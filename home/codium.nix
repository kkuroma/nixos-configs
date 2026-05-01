{ inputs, pkgs, ... }:
let
  ovsx = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.open-vsx;
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = true;
    profiles.default.extensions = [
      ovsx."13xforever".language-x86-64-assembly
      ovsx.asvetliakov.vscode-neovim
      ovsx.bbenoist.doxygen
      ovsx.bbenoist.nix
      ovsx.cheshirekow.cmake-format
      ovsx.cschlosser.doxdocgen
      ovsx.detachhead.basedpyright
      ovsx.esbenp.prettier-vscode
      ovsx.franneck94.c-cpp-runner
      ovsx.franneck94.vscode-c-cpp-config
      ovsx.franneck94.vscode-c-cpp-dev-extension-pack
      ovsx.hyunjin.pymap
      ovsx."james-yu".latex-workshop
      ovsx."jeanp413".open-remote-ssh
      ovsx."jeff-hykin".better-cpp-syntax
      ovsx.kamikillerto.vscode-colorize
      ovsx.luma.jupyter
      ovsx."ms-azuretools".vscode-containers
      ovsx."ms-azuretools".vscode-docker
      ovsx."ms-python".debugpy
      ovsx."ms-python".python
      ovsx."ms-python".vscode-python-envs
      ovsx."ms-toolsai".jupyter
      ovsx."ms-toolsai".jupyter-hub
      ovsx."ms-toolsai".jupyter-keymap
      ovsx."ms-toolsai".jupyter-renderers
      ovsx."ms-toolsai".vscode-jupyter-cell-tags
      ovsx."ms-toolsai".vscode-jupyter-slideshow
      ovsx.qwtel.sqlite-viewer
      ovsx.tamasfe.even-better-toml
      ovsx.twxs.cmake
      ovsx.vadimcn.vscode-lldb
      ovsx.vscodevim.vim
      ovsx.noctalia.noctaliatheme
    ];
  };
}
