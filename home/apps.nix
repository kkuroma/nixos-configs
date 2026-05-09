{ pkgs, ... }:
let
  # code-launcher, my signature vscode file picker
  # spawns a floating ghostty (formerly kitty) terminal, searches in ~, launchs in vscode
  initShell = pkgs.writeShellScriptBin "init-shell" ''
    set -e
    PYTHON=0; NPX=0; NETWORKING=0; CUDA=0
    for arg in "$@"; do
      case $arg in
        --python) PYTHON=1 ;;
        --npx) NPX=1 ;;
        --networking) NETWORKING=1 ;;
        --cuda) CUDA=1 ;;
        --help|-h) echo "Usage: init-shell [--python] [--npx] [--networking] [--cuda]"; exit 0 ;;
        *) echo "Unknown flag: $arg"; exit 1 ;;
      esac
    done
    if [ -f flake.nix ]; then
      echo "flake.nix already exists. Aborting."; exit 1
    fi
    PKGS=()
    [ $PYTHON -eq 1 ] && PKGS+=(python3 uv ruff black pyright)
    [ $NPX -eq 1 ]    && PKGS+=(nodejs)
    [ $NETWORKING -eq 1 ] && PKGS+=(nmap masscan gobuster ffuf sqlmap nikto john hashcat hydra netcat-gnu wireshark tcpdump)
    [ $CUDA -eq 1 ]   && PKGS+=(cudaPackages.cuda_cudart cudaPackages.libcublas cudaPackages.cuda_cccl)
    # single-quoted so ''${...} is preserved as literal nix text, not expanded by bash
    CUDA_HOOK='        export LD_LIBRARY_PATH=''${lib.makeLibraryPath (with pkgs; [ stdenv.cc.cc.lib zlib libGL cudaPackages.cuda_cudart cudaPackages.libcublas cudaPackages.cuda_cccl ])}:$LD_LIBRARY_PATH'
    {
      cat << 'HEADER'
    {
      description = "Dev shell";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
      outputs = { self, nixpkgs }:
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        lib = nixpkgs.lib;
      in {
        devShells.x86_64-linux.default = pkgs.mkShell {
          packages = with pkgs; [
    HEADER
      for p in "''${PKGS[@]}"; do printf "        %s\n" "$p"; done
      cat << 'MIDSECTION'
          ];
          shellHook = ''''
    MIDSECTION
      if [ $PYTHON -eq 1 ] || [ $CUDA -eq 1 ]; then
        printf '%s\n' '        if [ ! -d .venv ]; then uv venv; fi'
        printf '%s\n' '        source .venv/bin/activate'
      fi
      [ $CUDA -eq 1 ] && echo "$CUDA_HOOK"
      cat << 'FOOTER'
          '''';
        };
      };
    }
    FOOTER
    } > flake.nix
    echo "Generated flake.nix — running nix flake lock..."
    nix flake lock
    echo "use flake" > .envrc
    direnv allow
    echo "Done. cd out and back in to auto-activate, or run: nix develop ."
  '';

  codeLauncher = pkgs.writeShellScriptBin "code-launcher" ''
    path=$(${pkgs.fd}/bin/fd -H -E .git -t f -t d . ~/ \
      | ${pkgs.fzf}/bin/fzf \
          --pointer="" \
          --marker="" \
          --prompt="Open in VSCode: " \
          --height=100% \
          --reverse \
          --preview="${pkgs.bat}/bin/bat --color=always --style=numbers {}" \
          --preview-window=right:50%:wrap \
          --color=fg:7,bg:-1,hl:4,fg+:7,bg+:-1,hl+:4,info:2,prompt:4,pointer:3,marker:7,spinner:7,header:4)
    if [ -n "$path" ]; then
      nohup ${pkgs.vscodium}/bin/codium --ozone-platform=wayland "$path" > /dev/null 2>&1 &
      ${pkgs.libnotify}/bin/notify-send -a "System" "Code launcher" "Launched VSCode: $path" -i preferences-desktop
    fi
  '';
in
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y"; 
  };
  programs.btop.enable = true;
  programs.mpv.enable = true;
  programs.zathura.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    # development
    claude-code
    codeLauncher
    initShell
    texliveFull
    (python3.withPackages (ps: with ps; [ numpy pandas scipy matplotlib requests ipython ]))
    uv
    nodejs

    # nvim formatters (used by conform-nvim)
    nixfmt
    black
    stylua
    prettier

    # GUI apps
    feishin
    obs-studio
    vesktop
    vivaldi
    networkmanagerapplet
    kdePackages.dolphin
    kdePackages.kdenlive
    kdePackages.gwenview
    kdePackages.konsole
    prismlauncher
    imv
    libreoffice-qt
    hunspell
    hunspellDicts.th_TH

    # cli tools
    bat
    tesseract
    imagemagick
    zbar
    curl
    ffmpeg
    jq
    gifski
    grim
    imagemagick
    slurp
    distrobox
    util-linux
    fastfetch

    # themes
    wl-screenrec
    wl-clipboard

    # desktop shell
    papirus-icon-theme
    kdePackages.breeze
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    adwaita-qt6
    adw-gtk3

    # etc
    kdePackages.ark
    kdePackages.kde-cli-tools
    libnotify
  ];
}
