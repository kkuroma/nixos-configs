{ config, lib, ... }:
let
  ui     = config.rice.fonts.ui;
  mono   = config.rice.fonts.mono;
  uiSz   = "13";
  monoSz = "13";
  icon   = "Papirus-Dark";
  qtc    = "${config.home.homeDirectory}/.config";
in
{
  # adw-gtk3 is the base theme; noctalia applies its palette on top at runtime.
  # GTK4 (libadwaita) ignores gtk-theme and uses noctalia's color variables directly.
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme           = lib.mkDefault "adw-gtk3";
    font-name           = lib.mkDefault "${ui} ${uiSz}";
    document-font-name  = lib.mkDefault "${ui} ${uiSz}";
    monospace-font-name = lib.mkDefault "${mono} ${monoSz}";
  };

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

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${qtc}/qt6ct/colors/noctalia.conf
    custom_palette=true
    icon_theme=${icon}
    standard_dialogs=default
    style=Fusion

    [Fonts]
    fixed="${mono},${monoSz},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="${ui},${uiSz},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    color_scheme_path=${qtc}/qt5ct/colors/noctalia.conf
    custom_palette=true
    icon_theme=${icon}
    standard_dialogs=default
    style=Fusion

    [Fonts]
    fixed="${mono},${monoSz},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="${ui},${uiSz},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';
}
