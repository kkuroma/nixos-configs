{ pkgs, ... }:
{
  programs.neovim = { enable = true; withRuby = false; withPython3 = false; };
  programs.yazi   = { enable = true; shellWrapperName = "y"; };
  programs.btop.enable    = true;
  programs.mpv.enable     = true;
  programs.zathura.enable = true;
  programs.fzf = {
    enable               = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    # dev
    claude-code

    # GUI apps
    feishin
    obs-studio
    vesktop
    vivaldi
    networkmanagerapplet
    kdePackages.dolphin
    kdePackages.kdenlive
    prismlauncher
    imv

    # CLI tools
    ripgrep
    fd
    duf
    bottom
    procs
    ffmpeg
    fastfetch
    killall

    # GTK theming (noctalia applies colors on top of adw-gtk3)
    adw-gtk3

    # Misc
    gpu-screen-recorder
  ];
}
