{ lib, config, pkgs, niriParts, ... }:
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

    # X11 cursor theme for Xwayland windows.
    # Merged into the X server by the xwayland-satellite service after it starts.
    xdg.configFile."Xresources".text = ''
      Xcursor.theme: breeze_cursors
      Xcursor.size: 24
    '';

    # Expose DISPLAY in the systemd user environment so noctalia's launcher and
    # any other session-spawned process can start X11 apps without needing to
    # inherit it from a shell.  :0 matches the forced display number below.
    systemd.user.sessionVariables.DISPLAY = ":0";

    # Run xwayland-satellite as a proper session service instead of niri
    # spawn-at-startup so DISPLAY enters the systemd user environment.
    # Type=notify: xwayland-satellite calls sd_notify("READY=1") once the
    # display is accepting connections, so ExecStartPost runs only after :0 is up.
    systemd.user.services.xwayland-satellite = {
      Unit = {
        Description = "Xwayland rootless X display server";
        BindsTo = [ "graphical-session.target" ];
        After   = [ "graphical-session.target" ];
        PartOf  = [ "graphical-session.target" ];
      };
      Service = {
        Type         = "notify";
        NotifyAccess = "all";
        ExecStart    = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :0";
        ExecStartPost = "${pkgs.xrdb}/bin/xrdb -merge %h/.config/Xresources";
        Restart      = "on-failure";
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
