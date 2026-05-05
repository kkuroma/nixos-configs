{ pkgs, ... }:
let
  # code-launcher, my signature vscode file picker
  # spawns a floating ghostty (formerly kitty) terminal, searches in ~, launchs in vscode
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

  home.packages = with pkgs; [
    # development
    claude-code
    codeLauncher
    (texlive.combine { inherit (texlive) scheme-medium latexmk biber; })
    (python3.withPackages (ps: with ps; [ numpy pandas scipy matplotlib requests ipython ]))
    uv

    # nvim formatters (used by conform-nvim)
    nixfmt-rfc-style   # nix
    black              # python
    stylua             # lua
    nodePackages.prettier  # js/ts/json/yaml/md

    # GUI apps
    feishin
    obs-studio
    vesktop
    vivaldi
    networkmanagerapplet
    kdePackages.dolphin
    kdePackages.kdenlive
    kdePackages.gwenview
    prismlauncher
    imv
    onlyoffice-desktopeditors

    # etc
    bat
    libnotify
    adw-gtk3
    kdePackages.ark
    kdePackages.kde-cli-tools
    imagemagick
    gpu-screen-recorder
  ];
}
