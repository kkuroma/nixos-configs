{ config, lib, pkgs, ... }:
let
  upsName = "ups";
in
{
  sops.secrets."nut/monitor-password" = { mode = "0444"; };

  power.ups = {
    enable = true;
    mode = "standalone";

    ups.${upsName} = {
      driver = "blazer_usb";
      port = "auto";
      description = "Main UPS";
    };

    upsd.listen = [{ address = "127.0.0.1"; }];

    users.monitor = {
      passwordFile = config.sops.secrets."nut/monitor-password".path;
      upsmon = "primary";
    };

    upsmon.monitor.${upsName} = {
      system = "${upsName}@localhost";
      user = "monitor";
    };
  };

  # Shutdown when battery < 70% while on battery (OB status).
  # upsc reads are unauthenticated — no credentials needed here.
  systemd.services.ups-low-battery-shutdown = {
    description = "Initiate poweroff when UPS battery < 70% while on battery";
    after = [ "upsd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          check = pkgs.writeShellScript "ups-battery-check" ''
            status=$(${pkgs.nut}/bin/upsc ${upsName}@localhost ups.status 2>/dev/null) || exit 0
            charge=$(${pkgs.nut}/bin/upsc ${upsName}@localhost battery.charge 2>/dev/null) || exit 0
            case "$status" in
              *OB*)
                if [ "$charge" -lt 70 ]; then
                  logger -t ups-shutdown "UPS on battery at ''${charge}% — initiating safe shutdown"
                  systemctl poweroff
                fi
                ;;
            esac
          '';
        in
        "${check}";
    };
  };

  systemd.timers.ups-low-battery-shutdown = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "1min";
    };
  };
}
