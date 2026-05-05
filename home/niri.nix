{ lib, config, niriParts, ... }:
{
  options.rice.niri.extraConfig = lib.mkOption {
    type    = lib.types.lines;
    default = "";
  };

  config = {
    xdg.configFile."niri/config.kdl".text =
      # Cursor + input (was appearance.kdl + input.kdl)
      ''
        cursor {
            xcursor-theme "breeze_cursors"
            xcursor-size 24
        }

        input {
            focus-follows-mouse max-scroll-amount="0%"
        }

        spawn-at-startup "noctalia-shell"
        spawn-at-startup "xwayland-satellite"

      '' +
      # KDL parts: noctalia.kdl (colors/rules), keybinds.kdl
      lib.concatMapStrings builtins.readFile niriParts +
      # code-launcher floating rule; niri overview uses GTK font → rice.fonts.ui via dconf
      ''

        window-rule {
            match app-id="ghostty[.]float"
            open-floating true
        }

      '' +
      # Host-specific output config (set in hosts/<name>/home.nix)
      config.rice.niri.extraConfig;

    home.activation.niriNoctaliaFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.config/niri/noctalia.kdl" ]; then
        echo "// placeholder — noctalia will overwrite this on first run" \
          > "$HOME/.config/niri/noctalia.kdl"
      fi
    '';
  };
}
