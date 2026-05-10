{ ... }:
{
  # Framework 13 built-in display. Scale 2.0 → 1440x960 logical resolution.
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
