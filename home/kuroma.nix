{ config, inputs, pkgs, ... }:
let
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
in
{
  imports = [ ./niri.nix ./codium.nix ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";

  # qt6ct — HM manages everything except colors/ (noctalia writes noctalia.conf there)
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
    custom_palette=true
    icon_theme=${iconTheme.name}
    standard_dialogs=default
    style=Fusion

    [Fonts]
    fixed="Noto Sans Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  '';

  # KDE apps (Dolphin etc.) read icon theme and fonts from kdeglobals
  xdg.configFile."kdeglobals".text = ''
    [Icons]
    Theme=${iconTheme.name}

    [General]
    font=Noto Sans,11,-1,5,400,0,0,0,0,0
    fixed=Noto Sans Mono,10,-1,5,400,0,0,0,0,0
    smallestReadableFont=Noto Sans,8,-1,5,400,0,0,0,0,0
    toolBarFont=Noto Sans,10,-1,5,400,0,0,0,0,0
    menuFont=Noto Sans,11,-1,5,400,0,0,0,0,0
  '';

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    iconTheme = iconTheme;
    cursorTheme = {
      name = "breeze_cursors";
      package = pkgs.kdePackages.breeze;
      size = 24;
    };
    font = {
      name = "Noto Sans";
      size = 11;
    };
    gtk4.theme = null;
  };
}
