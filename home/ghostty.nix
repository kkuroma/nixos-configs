{ config, ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      "font-family"      = config.rice.fonts.mono;
      "font-size"        = 10;
      "window-decoration" = false;
      "scrollback-limit" = 10000;
      "cursor-style"     = "bar";
      "copy-on-select"   = "clipboard";
      "config-file"      = "~/.config/ghostty/config.ghostty";
      "gtk-custom-css"   = "notebook tab label { font-size: 14px; }";
    };
  };
}
