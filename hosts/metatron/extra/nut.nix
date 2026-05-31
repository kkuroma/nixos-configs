{ config, lib, pkgs, ... }:
let
  upsName = "ups";
  recipientEmail = "contact@kuroma.dev";

  notifyScript = pkgs.writeShellScript "ups-notify-email" ''
    msg="$*"
    {
      printf 'From: Metatron UPS Monitor <noreply@metatron>\r\n'
      printf 'To: ${recipientEmail}\r\n'
      printf 'Subject: [Metatron] your UPS is cooked: %s\r\n' "$msg"
      printf 'Content-Type: text/plain\r\n'
      printf '\r\n'
      printf '%s\n\n-- metatron UPS monitor\n' "$msg"
    } | ${pkgs.msmtp}/bin/msmtp \
          --file=${config.sops.templates."msmtp-config".path} \
          "${recipientEmail}"
  '';
in
{
  sops.secrets."nut/monitor-password"      = { mode = "0444"; };
  sops.secrets."vaultwarden/smtp-password" = { mode = "0444"; };

  sops.templates."msmtp-config" = {
    mode = "0444";
    content = ''
      account default
      host smtp.zoho.com
      port 587
      tls on
      tls_starttls on
      auth on
      user contact@kuroma.dev
      password ${config.sops.placeholder."vaultwarden/smtp-password"}
      from contact@kuroma.dev
      logfile /var/log/msmtp-ups.log
    '';
  };

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

    upsmon.settings = {
      NOTIFYCMD = "${notifyScript}";
      NOTIFYFLAG = [
        [ "ONBATT" "SYSLOG+EXEC" ]
        [ "ONLINE" "SYSLOG+EXEC" ]
        [ "LOWBATT" "SYSLOG+EXEC" ]
        [ "COMMBAD" "SYSLOG+EXEC" ]
        [ "COMMOK" "SYSLOG+EXEC" ]
        [ "SHUTDOWN" "SYSLOG+EXEC" ]
      ];
    };
  };

  # Shutdown when battery < 70% while on battery (OB status).
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
