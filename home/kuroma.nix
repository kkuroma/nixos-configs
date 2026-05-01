{ config, pkgs, ... }:
let
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
in
{
  imports = [ ./hyprland.nix ./codium.nix ];

  # Expose iconTheme to all imported modules (hyprland.nix reads it)
  _module.args.iconTheme = iconTheme;

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf
    custom_palette=true
    icon_theme=${iconTheme.name}
    standard_dialogs=default
    style=Fusion

    [Fonts]
    fixed="Noto Sans Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
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
