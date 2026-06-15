#!/usr/bin/env bash
# Install themes for a macOS dev machine.
# Run from anywhere — paths are relative to this script.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SRC="$SCRIPT_DIR/src"

# ── helpers ──────────────────────────────────────────────────────────────────

install_terminal() {
  echo "==> Terminal.app — importing Catppuccin Mocha profile"
  open "$SRC/catppuccin-mocha.terminal"
  echo "    Terminal will prompt you to add the profile."
  echo "    Set it as default in Terminal > Settings > Profiles."
}

install_vscode() {
  local dest="$HOME/Library/Application Support/Code/User"
  mkdir -p "$dest"
  echo "==> VS Code — copying settings.json + keybindings.json"
  cp "$SRC/settings.json"    "$dest/settings.json"
  cp "$SRC/keybindings.json" "$dest/keybindings.json"
  echo "    Written to: $dest"
}

install_zsh() {
  echo "==> Zsh — installing .zshrc"
  if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    echo "    Backed up existing .zshrc to ~/.zshrc.bak"
  fi
  cp "$SRC/.zshrc" "$HOME/.zshrc"
  echo "    Written to: ~/.zshrc"
  echo "    Dependencies (brew install): zsh-autosuggestions zsh-syntax-highlighting zoxide lsd"
}

# ── menu ─────────────────────────────────────────────────────────────────────

echo ""
echo "  Install themes"
echo "  ─────────────"
echo "  1) Terminal.app — Catppuccin Mocha profile"
echo "  2) VS Code      — keybindings + UI layout (no theme)"
echo "  3) Zsh          — .zshrc with prompt and aliases"
echo "  A) All of the above"
echo ""
read -rp "Choice [1/2/3/A]: " choice

case "${choice,,}" in
  1) install_terminal ;;
  2) install_vscode ;;
  3) install_zsh ;;
  a) install_terminal; install_vscode; install_zsh ;;
  *) echo "Unknown choice: $choice"; exit 1 ;;
esac

echo ""
echo "Done."
