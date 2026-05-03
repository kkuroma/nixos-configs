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
    (texlive.combine { inherit (texlive) scheme-medium latexmk biber; })

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

    # GTK theming (noctalia applies colors on top of adw-gtk3)
    adw-gtk3

    # Misc
    gpu-screen-recorder
  ];
}
