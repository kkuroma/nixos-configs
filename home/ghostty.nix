{ config, lib, ... }:
{
  home.activation.ghosttyConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="$HOME/.config/ghostty/config.ghostty"
    if [ ! -f "$config_file" ]; then
      echo "theme = noctalia" > "$config_file"
    fi
  '';

  programs.ghostty = {
    enable = true;
    settings = {
      "font-family" = config.rice.fonts.mono;
      "font-size" = 10;
      "window-decoration" = false;
      "scrollback-limit" = 10000;
      "cursor-style" = "bar";
      "copy-on-select" = "clipboard";
      "theme" = "noctalia";
      "config-file" = "~/.config/ghostty/config.ghostty";
      "gtk-custom-css" = "notebook tab label { font-size: 14px; }";
    };
  };
}
