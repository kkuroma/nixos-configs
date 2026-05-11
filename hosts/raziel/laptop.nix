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
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      ExecStart = "${pkgs.writeShellScript "lock-before-sleep" ''
        /run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock
        sleep 0.3
      ''}";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="ucsi-source-psy-USBC000:00[14]", ACTION=="change", RUN+="${pkgs.writeShellScript "charge-limit" ''
      LEFT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:001/online)
      RIGHT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:004/online)

      if [ "$LEFT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 80
      elif [ "$RIGHT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 100
      fi

      if [ "$LEFT_ON" = "1" ] || [ "$RIGHT_ON" = "1" ]; then
        ${pkgs.util-linux}/bin/runuser -u kuroma -- env XDG_RUNTIME_DIR=/run/user/1000 /run/current-system/sw/bin/noctalia-shell ipc --any-display call idleInhibitor enable
      else
        ${pkgs.util-linux}/bin/runuser -u kuroma -- env XDG_RUNTIME_DIR=/run/user/1000 /run/current-system/sw/bin/noctalia-shell ipc --any-display call idleInhibitor disable
      fi
    ''}"
  '';
}
