{ lib, config, pkgs, niriParts, machineConfig, ... }:
let
  # Renders a display attrset to a niri output {} KDL block.
  # Required fields: output, mode, x, y
  # Optional fields: transform, scale, defaultColumnWidth (KDL value string e.g. "proportion 1.0"),
  #                  gaps (default 6), borderWidth (default 2), focusRingWidth (default 2)
  renderDisplay = d:
    let
      gaps = d.gaps or 12;
      bw   = d.borderWidth or 3;
      frw  = d.focusRingWidth or 3;
    in
    "output \"${d.output}\" {\n"
    + "    mode \"${d.mode}\"\n"
    + "    position x=${toString d.x} y=${toString d.y}\n"
    + lib.optionalString (d ? transform) "    transform \"${d.transform}\"\n"
    + lib.optionalString (d ? scale) "    scale ${toString d.scale}\n"
    + "    layout {\n"
    + "        gaps ${toString gaps}\n"
    + "        border { width ${toString bw}; }\n"
    + "        focus-ring { width ${toString frw}; }\n"
    + lib.optionalString (d ? defaultColumnWidth) "        default-column-width { ${d.defaultColumnWidth}; }\n"
    + "    }\n"
    + "}\n";
in
{
  options.rice.niri.extraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Extra KDL appended after output blocks. Use for overrides that don't fit machineConfig.displays.";
  };

  config = {
    xdg.configFile."niri/config.kdl".text =
      ''
        cursor {
            xcursor-theme "breeze_cursors"
            xcursor-size 24
        }
        input {
            focus-follows-mouse max-scroll-amount="0%"
            touchpad {
                tap
                tap-button-map "left-right-middle"
            }
        }
        spawn-at-startup "noctalia"
        spawn-at-startup "tailscale" "systray"
      '' +
      lib.concatMapStrings builtins.readFile niriParts +
      lib.concatMapStrings renderDisplay machineConfig.displays +
      ''
        prefer-no-csd
        window-rule {
            match app-id="ghostty[.]float"
            open-floating true
        }
        window-rule {
            match app-id="imv"
            open-floating true
        }
        window-rule {
            match app-id="mpv"
            open-floating true
        }
      '' +
      config.rice.niri.extraConfig;
    xdg.configFile."Xresources".text = ''
      Xcursor.theme: breeze_cursors
      Xcursor.size: 24
    '';

    systemd.user.sessionVariables.DISPLAY = ":0";
    systemd.user.services.xwayland-satellite = {
      Unit = {
        Description = "Xwayland rootless X display server";
        BindsTo = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "notify";
        NotifyAccess = "all";
        ExecStartPre = "-${pkgs.coreutils}/bin/rm -f /tmp/.X0-lock /tmp/.X11-unix/X0";
        ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :0";
        ExecStartPost = "${pkgs.xrdb}/bin/xrdb -merge %h/.config/Xresources";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.polkit-gnome = {
      Unit = {
        Description = "GNOME Polkit authentication agent";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    home.activation.niriNoctaliaFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.config/niri/noctalia.kdl" ]; then
        echo "// placeholder — noctalia will overwrite this on first run" \
          > "$HOME/.config/niri/noctalia.kdl"
      fi
    '';
  };
}
