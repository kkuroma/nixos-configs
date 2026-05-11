{ ... }:
{
  # swayidle installed and configured to lock screen BEFORE sleep/hibernate
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
