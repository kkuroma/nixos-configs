#!/usr/bin/env bash
set -euo pipefail

PYTHON=0; NPX=0; NETWORKING=0; CUDA=0; GIT=0
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --python)     PYTHON=1 ;;
    --npx)        NPX=1 ;;
    --networking) NETWORKING=1 ;;
    --cuda)       CUDA=1 ;;
    --git)        GIT=1 ;;
    --name)       shift; NAME="$1" ;;
    --name=*)     NAME="${1#--name=}" ;;
    --help|-h)
      cat << 'EOF'
Usage: init-shell [flags] [--name NAME]

Generates flake.nix + .envrc in the current directory.

  --python     Python dev tools (uv, ruff, black, pyright) — Python packages go in uv
  --cuda       CUDA libraries + LD_LIBRARY_PATH hook (independent of --python)
  --npx        Node.js / npx
  --networking Network/security tools (nmap, ffuf, gobuster, ...)
  --git        git init (if not already a repo) + .gitignore + git in devShell
  --name NAME  Shell name shown in starship prompt (default: directory name)
  -h, --help   Show this help

TIP: Run in an empty project directory. Running in a large existing directory
causes nix flake lock to copy everything to the Nix store.
Use --git so Nix can filter via .gitignore instead.
EOF
      exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

if [ -f flake.nix ]; then
  echo "flake.nix already exists. Aborting." >&2
  exit 1
fi

FILE_COUNT=$(find . -maxdepth 1 ! -name '.*' ! -name '.' | wc -l)
if [ "$FILE_COUNT" -gt 50 ]; then
  echo "Warning: $FILE_COUNT files in current directory." >&2
  echo "nix flake lock will copy all of them to the Nix store." >&2
  echo "Consider running in an empty subdirectory, or use --git so Nix filters via .gitignore." >&2
fi


SHELL_NAME="${NAME:-$(basename "$PWD")}"

PKGS=()
[ $PYTHON -eq 1 ] && PKGS+=(python3 uv ruff black pyright)
[ $NPX -eq 1 ] && PKGS+=(nodejs)
[ $CUDA -eq 1 ] && PKGS+=(cudaPackages.cuda_cudart cudaPackages.libcublas cudaPackages.cuda_cccl)
[ $NETWORKING -eq 1 ] && PKGS+=(nmap masscan gobuster ffuf sqlmap nikto john hashcat hydra netcat-gnu wireshark tcpdump)
[ $GIT -eq 1 ] && PKGS+=(git)

# generate flake.nix
{
cat << HEADER
{
  description = "${SHELL_NAME}";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
    lib = nixpkgs.lib;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
HEADER

for p in "${PKGS[@]}"; do printf "        %s\n" "$p"; done

# Close packages list, then emit mkShell-level env vars
cat << 'PKGSEND'
      ];
PKGSEND

printf '      DEV_SHELL = "%s";\n' "$SHELL_NAME"

if [ $CUDA -eq 1 ]; then
cat << 'CUDAENV'
      LD_LIBRARY_PATH = "/run/opengl-driver/lib:" + lib.makeLibraryPath (with pkgs; [ stdenv.cc.cc.lib zlib libGL cudaPackages.cuda_cudart cudaPackages.libcublas cudaPackages.cuda_cccl ]);
CUDAENV
elif [ $PYTHON -eq 1 ]; then
# stdenv.cc.cc.lib provides libstdc++.so.6 needed by uv-installed C extensions (numpy, torch, etc.)
cat << 'PYENV'
      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ stdenv.cc.cc.lib zlib ]);
PYENV
fi

cat << 'SHELLHOOK'
      shellHook = ''
SHELLHOOK

if [ $PYTHON -eq 1 ]; then
# Only activate an existing venv — creation is done by init-shell's bootstrap command
cat << 'VENV'
        if [ -d .venv ]; then
          export VIRTUAL_ENV="$PWD/.venv"
          export PATH="$PWD/.venv/bin:$PATH"
        fi
VENV
fi

cat << 'FOOTER'
        [[ $- == *i* ]] && exec zsh
      '';
    };
  };
}
FOOTER
} > flake.nix

# Python project scaffold (uv)
if [ $PYTHON -eq 1 ]; then
  uv init --no-readme --no-workspace -q
  uv lock -q
fi

# git
if [ $GIT -eq 1 ]; then
  if [ -d .git ]; then
    echo "Note: already a git repo — skipping git init."
  else
    git init -q
  fi
  if [ ! -f .gitignore ]; then
    cat > .gitignore << 'GITIGNORE'
.direnv/
.venv/
.history
*.pyc
__pycache__/
node_modules/
result
GITIGNORE
  fi
fi

# codium python interpreter
if [ $PYTHON -eq 1 ]; then
  mkdir -p .vscode
  if [ ! -f .vscode/settings.json ]; then
    cat > .vscode/settings.json << 'VSCODE'
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
VSCODE
  fi
fi

# direnv
echo "use flake" > .envrc

# Stage all generated files before bootstrapping so nix develop sees the git tree
if [ $GIT -eq 1 ]; then
  git add .
fi

# Allow .envrc before nix develop — if nix develop fails under set -euo pipefail
direnv allow

# Bootstrap venv + ipykernel using the nix devShell Python
if [ $PYTHON -eq 1 ]; then
  echo "Bootstrapping venv (fetches nixpkgs if not cached)..."
  nix develop --command bash -c "uv venv -q && uv pip install ipykernel -q"
  if [ $GIT -eq 1 ]; then
    git add flake.lock 2>/dev/null || true
  fi
fi

echo ""
echo "Shell '${SHELL_NAME}' ready."
echo "  Terminal : nix develop"
echo "  VSCodium : open folder (direnv loads PATH automatically)"
if [ $PYTHON -eq 1 ] && [ $CUDA -eq 1 ]; then
  echo ""
  echo "  PyTorch CUDA: uv add torch  (routes to CUDA index automatically)"
fi
