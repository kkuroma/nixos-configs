{ pkgs, inputs, ... }:
{
  programs.hyprland.enable = true;
  programs.dconf.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      qt6Packages.fcitx5-chinese-addons
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.variables = {
    XCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "breeze_cursors";
    HYPRCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  environment.systemPackages = with pkgs; [
    # hyprland utils
    hyprlock
    hypridle
    nwg-displays
    xsettingsd
    firejail

    # bar, launcher, notifications, osd
    waybar
    walker
    elephant
    swaynotificationcenter
    swayosd

    # wallpaper
    awww
    glpaper

    # theming
    matugen
    papirus-icon-theme
    kdePackages.breeze
    qt6Packages.qt6ct
    adwaita-qt6
    adw-gtk3

    # terminal + file manager
    kitty
    yazi

    # apps
    feishin
    imv
    mpv
    wl-clipboard

    # browser — from community flake
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
