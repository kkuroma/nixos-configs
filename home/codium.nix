{ inputs, pkgs, lib, ... }:
let
  ovsx = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.open-vsx;

  # Patch engine version check so it loads with the current VSCodium build.
  latexWorkshop = pkgs.runCommand "latex-workshop-patched" {} ''
    cp -r ${ovsx."james-yu".latex-workshop} $out
    chmod -R u+w $out
    sed -i 's/"vscode": "\^[^"]*"/"vscode": "*"/' $out/package.json
  '';

  # Kept separate from the extensions list so HM doesn't create a read-only
  # nix-store symlink — noctalia needs to write its color theme file into it.
  noctaliaExt = ovsx.noctalia.noctaliatheme;
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = true;
    profiles.default = {
      extensions = [
        ovsx."13xforever".language-x86-64-assembly
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
        latexWorkshop
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
      ];

      userSettings = {
        "workbench.editor.showTabs"                       = "multiple";
        "workbench.activityBar.location"                  = "top";
        "workbench.statusBar.visible"                     = false;
        "window.menuBarVisibility"                        = "hidden";
        "window.commandCenter"                            = false;
        "window.controlsStyle"                            = "hidden";
        "window.titleBarStyle"                            = "custom";
        "window.dialogStyle"                              = "native";
        "window.zoomLevel"                                = -0.6;
        "window.confirmBeforeClose"                       = "always";
        "window.confirmSaveUntitledWorkspace"             = false;
        "editor.minimap.enabled"                          = false;
        "editor.minimap.renderCharacters"                 = false;
        "editor.formatOnSave"                             = true;
        "editor.defaultFormatter"                         = "esbenp.prettier-vscode";
        "editor.scrollbar.verticalScrollbarSize"          = 8;
        "editor.scrollbar.horizontalScrollbarSize"        = 8;
        "files.autoSave"                                  = "afterDelay";
        "security.workspace.trust.untrustedFiles"         = "open";
        "remote.autoForwardPortsSource"                   = "hybrid";
        "terminal.integrated.initialHint"                 = false;
        "terminal.integrated.stickyScroll.enabled"        = false;
        "terminal.integrated.enableMultiLinePasteWarning" = "never";
        "chat.restoreLastPanelSession"                    = true;
        "extensions.experimental.affinity"               = { "asvetliakov.vscode-neovim" = 1; };
        "workbench.editorAssociations" = {
          "{git,gitlens,chat-editing-snapshot-text-model,copilot,git-graph,git-graph-3}:/**/*.qrc" = "default";
          "*.qrc" = "qt-core.qrcEditor";
        };
        "explorer.fileNesting.patterns" = {
          "*.ts"          = "\${capture}.js";
          "*.js"          = "\${capture}.js.map, \${capture}.min.js, \${capture}.d.ts";
          "*.jsx"         = "\${capture}.js";
          "*.tsx"         = "\${capture}.ts";
          "tsconfig.json" = "tsconfig.*.json";
          "package.json"  = "package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb, bun.lock";
          "*.sqlite"      = "\${capture}.\${extname}-*";
          "*.db"          = "\${capture}.\${extname}-*";
          "*.sqlite3"     = "\${capture}.\${extname}-*";
          "*.db3"         = "\${capture}.\${extname}-*";
          "*.sdb"         = "\${capture}.\${extname}-*";
          "*.s3db"        = "\${capture}.\${extname}-*";
        };
      };
    };
  };

  # Copy noctalia extension from nix store to a writable directory.
  # A sentinel file tracks the store path so it re-copies on extension updates.
  home.activation.noctaliaThemeExtension = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${noctaliaExt}"
    dest="$HOME/.vscode-oss/extensions/noctalia.noctaliatheme"
    if [ ! -d "$dest" ] || [ "$(cat "$dest/.nix-src" 2>/dev/null)" != "$src" ]; then
      rm -rf "$dest"
      cp -r "$src" "$dest"
      chmod -R u+w "$dest"
      printf '%s' "$src" > "$dest/.nix-src"
    fi
  '';
}
