{ inputs, pkgs, lib, config, ... }:
let
  ovsx = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.open-vsx;

  # latex workshop requires patch to work regardless of vscodium verion, so we fix it
  latexWorkshop = (ovsx."james-yu".latex-workshop).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      sed -i 's/"vscode": "\^[^"]*"/"vscode": "^1.0.0"/' \
        $out/share/vscode/extensions/james-yu.latex-workshop/package.json
    '';
  });

  # noctalia path to ignore for extension manager HM modules
  noctaliaExt = ovsx.noctalia.noctaliatheme;
  noctaliaExtVersion = (lib.importJSON "${noctaliaExt}/share/vscode/extensions/noctalia.noctaliatheme/package.json").version;
  noctaliaExtDirName = "noctalia.noctaliatheme-${noctaliaExtVersion}-universal";

  # extension list: used to generate vscodium's extensions at .vscode-oss and extensions.json
  extList = [
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
    ovsx.v1hz.kdl
  ];

  # extensions json template
  extensionsJsonTemplate = pkgs.writeText "vscodium-extensions.json" (builtins.toJSON (
    (map (ext: {
      identifier.id = ext.vscodeExtUniqueId;
      version = ext.version;
      location = { "$mid" = 1; path = "__EXT_DIR__/${ext.vscodeExtUniqueId}"; scheme = "file"; };
      relativeLocation = ext.vscodeExtUniqueId;
    }) extList)
    ++ [{
      identifier.id = noctaliaExt.vscodeExtUniqueId;
      version = noctaliaExtVersion;
      location = { "$mid" = 1; path = "__EXT_DIR__/${noctaliaExtDirName}"; scheme = "file"; };
      relativeLocation = noctaliaExtDirName;
    }]
  ));

  # settings, exported from my old vscodium session, turned into nix
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

  keybindings = [
    { key = "ctrl+p";          command = "workbench.action.quickOpen"; }
    { key = "ctrl+e";          command = "-workbench.action.quickOpen"; }
    { key = "ctrl+alt+w";      command = "workbench.action.closeActiveEditor"; }
    { key = "ctrl+w";          command = "-workbench.action.closeActiveEditor"; }
    { key = "ctrl+shift+t";    command = "workbench.action.createTerminalEditor"; }
    { key = "ctrl+shift+b";    command = "workbench.action.browser.open"; }
    { key = "ctrl+shift+b";    command = "-workbench.action.tasks.build";
      when = "taskCommandsRegistered"; }
    { key = "ctrl+c";          command = "-extension.vim_ctrl+c";
      when = "editorTextFocus && vim.active && vim.overrideCtrlC && vim.use<C-c> && !inDebugRepl"; }
    { key = "ctrl+alt+a";      command = "notebook.cell.insertCodeCellAboveAndFocusContainer";
      when = "notebookEditorFocused && !inputFocus && !notebookOutputInputFocused"; }
    { key = "a";               command = "-notebook.cell.insertCodeCellAboveAndFocusContainer";
      when = "notebookEditorFocused && !inputFocus && !notebookOutputInputFocused"; }
    { key = "ctrl+enter";      command = "-notebook.cell.insertCodeCellBelow";
      when = "notebookCellListFocused && !inputFocus"; }
    { key = "ctrl+alt+b";      command = "notebook.cell.insertCodeCellBelowAndFocusContainer";
      when = "notebookEditorFocused && !inputFocus && !notebookOutputInputFocused"; }
    { key = "b";               command = "-notebook.cell.insertCodeCellBelowAndFocusContainer";
      when = "notebookEditorFocused && !inputFocus && !notebookOutputInputFocused"; }
    { key = "ctrl+alt+b";      command = "-workbench.action.toggleAuxiliaryBar"; }
    { key = "ctrl+a";          command = "-extension.vim_ctrl+a";
      when = "editorTextFocus && vim.active && vim.use<C-a> && !inDebugRepl"; }
    { key = "ctrl+x";          command = "-extension.vim_ctrl+x";
      when = "editorTextFocus && vim.active && vim.use<C-x> && !inDebugRepl"; }
    { key = "ctrl+f";          command = "-extension.vim_ctrl+f";
      when = "editorTextFocus && vim.active && vim.use<C-f> && !inDebugRepl && vim.mode != 'Insert'"; }
  ];

  keybindingsFile = pkgs.writeText "vscodium-keybindings.json" (builtins.toJSON keybindings);
in
{
  programs.vscodium = {
    enable = true;
    mutableExtensionsDir = true;
    profiles.default.extensions = extList;
  };

  # Patch 1 - Write a make settions.json mutable so noctalia can update workbench.colorTheme
  # tracks the nix store path so it re-writes only when settings change
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

  home.activation.vscodiumKeybindings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/.config/VSCodium/User/keybindings.json"
    sentinel="$HOME/.config/VSCodium/User/.keybindings-nix-src"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${keybindingsFile}" ]; then
      cp "${keybindingsFile}" "$dest"
      chmod u+w "$dest"
      printf '%s' "${keybindingsFile}" > "$sentinel"
    fi
  '';

  # Path 2 - extensions.json clear itself when rebuild
  # generates extensions.json from nix so codium recognizes the above extensions
  home.activation.vscodiumExtensionsJson = lib.hm.dag.entryAfter [ "writeBoundary" "noctaliaThemeExtension" ] ''
    _ext_dir="$HOME/.vscode-oss/extensions"
    _sentinel="$_ext_dir/.nix-extensions-gen"
    if [ "$(cat "$_sentinel" 2>/dev/null)" != "${extensionsJsonTemplate}" ]; then
      _content=$(< "${extensionsJsonTemplate}")
      _content="''${_content//__EXT_DIR__/$_ext_dir}"
      printf '%s' "$_content" > "$_ext_dir/extensions.json"
      printf '%s' "${extensionsJsonTemplate}" > "$_sentinel"
    fi
  '';

  # Patch 3 - noctalia color theme has to be mutable
  # this prevents $HOME/.vscode-oss/extensions/${noctaliaExtDirName} from being HM'ed
  # so noctalia is able to write the color and live-change codium's theme with the desktop
  home.activation.noctaliaThemeExtension = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${noctaliaExt}/share/vscode/extensions/noctalia.noctaliatheme"
    dest="$HOME/.vscode-oss/extensions/${noctaliaExtDirName}"
    # Remove unversioned and .backup copies left by previous activations or HM
    rm -rf "$HOME/.vscode-oss/extensions/noctalia.noctaliatheme"
    rm -rf "$HOME/.vscode-oss/extensions/noctalia.noctaliatheme.backup"
    # Remove old versioned dirs from previous package versions, but not the current one
    for _d in "$HOME"/.vscode-oss/extensions/noctalia.noctaliatheme-*; do
      [ -d "$_d" ] && [ "$_d" != "$dest" ] && rm -rf "$_d"
    done
    # Recopy only when the nix store source changes; preserve generated theme file
    if [ "$(cat "$dest/.nix-src" 2>/dev/null)" != "$src" ]; then
      _theme="$dest/themes/NoctaliaTheme-color-theme.json"
      [ -f "$_theme" ] && cp "$_theme" /tmp/_noctalia-theme.json
      rm -rf "$dest"
      cp -r "$src" "$dest"
      chmod -R u+w "$dest"
      printf '%s' "$src" > "$dest/.nix-src"
      [ -f /tmp/_noctalia-theme.json ] && mv /tmp/_noctalia-theme.json "$_theme"
    fi
  '';
}
