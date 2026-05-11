{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.fw-ectool ];

  services.udev.packages = [ pkgs.brightnessctl ];

  services.logind.settings.Login.HandlePowerKey = "suspend-then-hibernate";

  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;
  services.fwupd.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="ucsi-source-psy-USBC000:00[14]", ACTION=="change", RUN+="${pkgs.writeShellScript "charge-limit" ''
      LEFT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:001/online)
      RIGHT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:004/online)
      if [ "$LEFT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 80
      elif [ "$RIGHT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 100
      fi
    ''}"
  '';
}
