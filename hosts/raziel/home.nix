{ ... }:
{
  systemd.user.services.lock-before-sleep = {
    Unit = {
      Description = "Lock screen before sleep";
      Before = [ "sleep.target" ];
    };
    Install.WantedBy = [ "sleep.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      # noctalia IPC returns immediately; sleep 1 lets the lock screen render before suspend proceeds
      ExecStart = "/bin/sh -c '/run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock; sleep 1'";
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

    binds {
        XF86PowerOff { spawn-sh "noctalia-shell ipc --any-display call lockScreen lock && sleep 1 && systemctl suspend-then-hibernate"; }
    }
  '';
}
