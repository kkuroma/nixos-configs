#!/usr/bin/env bash
# VS Code extension installer for macOS dev machine
# Run: bash install-extensions.sh
set -euo pipefail

CODE=code
command -v "$CODE" &>/dev/null || { echo "error: 'code' not in PATH — open VS Code, run 'Shell Command: Install code in PATH'"; exit 1; }

install() { "$CODE" --install-extension "$1" --force; }

echo "==> Python"
install ms-python.python
install ms-python.debugpy
install ms-python.pylance
install ms-python.vscode-python-envs

echo "==> Jupyter"
install ms-toolsai.jupyter
install ms-toolsai.jupyter-renderers
install ms-toolsai.jupyter-keymap
install ms-toolsai.vscode-jupyter-cell-tags
install ms-toolsai.vscode-jupyter-slideshow

echo "==> Docker / containers"
install ms-azuretools.vscode-docker
install ms-azuretools.vscode-containers

echo "==> Remote / SSH"
install ms-vscode-remote.remote-ssh
install ms-vscode-remote.remote-ssh-edit

echo "==> Git"
install eamodio.gitlens

echo "==> General dev"
install esbenp.prettier-vscode
install tamasfe.even-better-toml
install qwtel.sqlite-viewer
install mkhl.direnv
install kamikillerto.vscode-colorize

echo "==> Vim"
install vscodevim.vim

echo "==> Theme / icons"
install catppuccin.catppuccin-vsc
install pkief.material-icon-theme

echo ""
echo "Done. Open VS Code settings to set:"
echo "  workbench.colorTheme  → Catppuccin Mocha"
echo "  workbench.iconTheme   → material-icon-theme"
