{ ... }:
{
  # Lock screen before any sleep (power button, lid close, manual suspend).
  # Runs in user session so it has Wayland access without runuser hacks.
  # -w: holds a systemd sleep inhibitor until the lock command exits,
  # so the display stays on long enough for the lock screen to render.
  services.swayidle = {
    enable = true;
    extraArgs = [ "-w" ];
    events = {
      before-sleep = "/run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock";
    };
  };

  rice.niri.extraConfig = ''
    output "eDP-1" {
        mode "2880x1920@120.000"
        position x=0 y=0
        scale 1.5
        layout {
            gaps 6
            border { width 2; }
            focus-ring { width 2; }
        }
    }

  '';
}
