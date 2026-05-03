{ inputs, pkgs, lib, config, ... }:
let
  ovsx = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.open-vsx;

  # Patch engine version check so it loads with the current VSCodium build.
  # overrideAttrs preserves vscodeExtUniqueId and other HM-required attributes.
  latexWorkshop = (ovsx."james-yu".latex-workshop).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      sed -i 's/"vscode": "\^[^"]*"/"vscode": "^1.0.0"/' \
        $out/share/vscode/extensions/james-yu.latex-workshop/package.json
    '';
  });

  # Kept separate from the extensions list so HM doesn't create a read-only
  # nix-store symlink — noctalia needs to write its color theme file into it.
  noctaliaExt = ovsx.noctalia.noctaliatheme;

  settings = {
    "workbench.colorTheme"                            = "NoctaliaTheme";
    "workbench.editor.showTabs"                       = "multiple";
    "workbench.activityBar.location"                  = "top";
    "workbench.statusBar.visible"                     = false;
    "window.menuBarVisibility"                        = "hidden";
    "window.commandCenter"                            = false;
    "window.controlsStyle"                            = "hidden";
    "window.titleBarStyle"                            = "custom";
    "window.dialogStyle"                              = "native";
    "window.zoomLevel"                                = -0.2;
    "window.confirmBeforeClose"                       = "always";
    "window.confirmSaveUntitledWorkspace"             = false;
    "editor.fontFamily"                               = "'${config.rice.fonts.mono}'";
    "editor.fontSize"                                 = 13;
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

  settingsFile = pkgs.writeText "vscodium-settings.json" (builtins.toJSON settings);
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = true;
    profiles.default.extensions = [
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
  };

  # Write a mutable settings.json so noctalia can update workbench.colorTheme at runtime.
  # Sentinel tracks the nix store path so it re-writes only when settings change.
  home.activation.vscodiumSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/.config/VSCodium/User/settings.json"
    sentinel="$HOME/.config/VSCodium/User/.settings-nix-src"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${settingsFile}" ]; then
      cp "${settingsFile}" "$dest"
      chmod u+w "$dest"
      printf '%s' "${settingsFile}" > "$sentinel"
    fi
  '';

  # Copy noctalia extension from nix store to a writable directory.
  # A sentinel file tracks the store path so it re-copies on extension updates.
  home.activation.noctaliaThemeExtension = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${noctaliaExt}/share/vscode/extensions/noctalia.noctaliatheme"
    dest="$HOME/.vscode-oss/extensions/noctalia.noctaliatheme"
    if [ ! -d "$dest" ] || [ "$(cat "$dest/.nix-src" 2>/dev/null)" != "$src" ]; then
      rm -rf "$dest"
      cp -r "$src" "$dest"
      chmod -R u+w "$dest"
      printf '%s' "$src" > "$dest/.nix-src"
    fi
  '';
}
