{ lib, config, pkgs, niriParts, ... }:
{
  options.rice.niri.extraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
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
        }
        spawn-at-startup "noctalia-shell"
      '' +
      lib.concatMapStrings builtins.readFile niriParts +
      ''
        prefer-no-csd
        window-rule {
            match app-id="ghostty[.]float"
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

    home.activation.niriNoctaliaFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.config/niri/noctalia.kdl" ]; then
        echo "// placeholder — noctalia will overwrite this on first run" \
          > "$HOME/.config/niri/noctalia.kdl"
      fi
    '';
  };
}
