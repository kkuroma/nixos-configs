{ pkgs, ... }:
let
  # code-launcher, my signature vscode file picker
  # spawns a floating ghostty (formerly kitty) terminal, searches in ~, launchs in vscode
  initShell = pkgs.writeShellScriptBin "init-shell"
    (builtins.readFile ./scripts/init-shell.sh);

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

  # code launcher, but for dolphin
  fileLauncher = pkgs.writeShellScriptBin "file-launcher" ''
    # -t d restricts fd to directories only
    # --max-depth can be added if ~/ is too slow
    path=$(${pkgs.fd}/bin/fd -H -E .git -t d . ~/ \
      | ${pkgs.fzf}/bin/fzf \
          --pointer="▶" \
          --marker="" \
          --prompt="Open Folder: " \
          --height=100% \
          --reverse \
          --preview="${pkgs.lsd}/bin/lsd --tree --depth 2 --color always {}" \
          --preview-window=right:50%:wrap \
          --color=fg:7,bg:-1,hl:4,fg+:7,bg+:-1,hl+:4,info:2,prompt:4,pointer:3,marker:7,spinner:7,header:4)

    if [ -n "$path" ]; then
      # Use setsid or disown to ensure the process survives the terminal closing
      setsid ${pkgs.kdePackages.dolphin}/bin/dolphin "$path" > /dev/null 2>&1 &
      ${pkgs.libnotify}/bin/notify-send -a "System" "File Browser" "Opening: $path" -i folder-open
    fi
  '';
in
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y"; 
  };
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
    fileLauncher
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
    onlyoffice-desktopeditors

    # cli tools
    brightnessctl
    playerctl
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
    ouch

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
