{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.fw-ectool ];

  services.udev.packages = [ pkgs.brightnessctl ];

  services.logind.settings.Login.HandlePowerKey = "suspend-then-hibernate";

  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;
  services.fwupd.enable = true;

  # System-scope service: user-scope sleep.target isn't reliably activated by logind
  systemd.services.lock-before-sleep = {
    description = "Lock screen before sleep";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "kuroma";
      Environment = [ "XDG_RUNTIME_DIR=/run/user/1000" "WAYLAND_DISPLAY=wayland-1" ];
      ExecStart = "${pkgs.writeShellScript "lock-before-sleep" ''
        /run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock
        sleep 0.5
      ''}";
      # Lock on resume too — the pre-sleep lock races the display blanking;
      # ExecStop runs when sleep.target deactivates (system fully awake again)
      ExecStop = "/run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="ucsi-source-psy-USBC000:00[14]", ACTION=="change", RUN+="${pkgs.writeShellScript "charge-limit" ''
      LEFT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:001/online)
      RIGHT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:004/online)

      AS_USER="${pkgs.util-linux}/bin/runuser -u kuroma -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"

      if [ "$LEFT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 80
        $AS_USER /run/current-system/sw/bin/noctalia-shell ipc --any-display call idleInhibitor enable
        $AS_USER ${pkgs.libnotify}/bin/notify-send -i battery-caution-charging "Charge limit" "80% — left port"
      elif [ "$RIGHT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 100
        $AS_USER /run/current-system/sw/bin/noctalia-shell ipc --any-display call idleInhibitor enable
        $AS_USER ${pkgs.libnotify}/bin/notify-send -i battery-full-charging "Charge limit" "100% — right port"
      else
        $AS_USER /run/current-system/sw/bin/noctalia-shell ipc --any-display call idleInhibitor disable
      fi
    ''}"
  '';
}
