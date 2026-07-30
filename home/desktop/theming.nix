{ config, lib, pkgs, ... }:
let
  ui = config.rice.fonts.ui;
  mono = config.rice.fonts.mono;
  uiSz = toString config.rice.fonts.uiSize;
  monoSz = toString config.rice.fonts.monoSize;
  icon = "Papirus-Dark";
  qtc = "${config.home.homeDirectory}/.config";

  mkQtCt = version: {
    Appearance = {
      color_scheme_path = "${qtc}/qt${version}ct/colors/noctalia.conf";
      custom_palette = true;
      icon_theme = icon;
      standard_dialogs = "default";
      style = "Fusion";
    };
    Fonts = {
      fixed = "${mono},${monoSz},-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      general = "${ui},${uiSz},-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    };
    Interface = {
      activate_item_on_single_click = 1;
      buttonbox_layout = 0;
      cursor_flash_time = 1000;
      dialog_buttons_have_icons = 1;
      double_click_interval = 400;
      gui_effects = "@Invalid()";
      keyboard_scheme = 2;
      menus_have_icons = true;
      show_shortcuts_in_context_menus = true;
      stylesheets = "@Invalid()";
      toolbutton_style = 4;
      underline_shortcut = 1;
      wheel_scroll_lines = 3;
    };
    Troubleshooting = {
      force_raster_widgets = 1;
      ignored_applications = "@Invalid()";
    };
  };

  iniFormat = pkgs.formats.ini { };
in
{
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = lib.mkDefault "adw-gtk3";
    icon-theme = lib.mkDefault icon;
    font-name = lib.mkDefault "${ui} ${uiSz}";
    document-font-name = lib.mkDefault "${ui} ${uiSz}";
    monospace-font-name = lib.mkDefault "${mono} ${monoSz}";
  };

  xdg.configFile."qt5ct/qt5ct.conf".source = iniFormat.generate "qt5ct.conf" (mkQtCt "5");
  xdg.configFile."qt6ct/qt6ct.conf".source = iniFormat.generate "qt6ct.conf" (mkQtCt "6");

  # GTK reads settings.ini before consulting dconf, so noctalia (spawned by niri
  # before dconf.service is up) finds the icon theme without needing a live D-Bus session.
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=${icon}
    gtk-theme-name=adw-gtk3
    gtk-font-name=${ui} ${uiSz}
  '';
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=${icon}
    gtk-theme-name=adw-gtk3
    gtk-font-name=${ui} ${uiSz}
  '';

  xdg.configFile."kdeglobals".text = ''
    [Icons]
    Theme=${icon}

    [General]
    ColorScheme=noctalia
    TerminalApplication=ghostty
    font=${ui},${uiSz},-1,5,400,0,0,0,0,0
    fixed=${mono},${monoSz},-1,5,400,0,0,0,0,0
    smallestReadableFont=${ui},8,-1,5,400,0,0,0,0,0
    toolBarFont=${ui},${uiSz},-1,5,400,0,0,0,0,0
    menuFont=${ui},${uiSz},-1,5,400,0,0,0,0,0

    [UiSettings]
    ColorScheme=noctalia
  '';
}
