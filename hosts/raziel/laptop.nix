{ pkgs, ... }:
{
  # Framework EC tool (battery charge limit, fan curves, etc.)
  environment.systemPackages = [ pkgs.fw-ectool ];

  # Fingerprint — Goodix MOC sensor (27c6:609c) on Framework 13 AMD AI 300
  # tod driver is required; generic libfprint does not support this sensor
  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  # Explicit fprint auth for the PAM services that ask for a password.
  # NixOS enables fprint broadly when fprintd is on, but sudo and polkit
  # are the ones users actually encounter for privilege escalation.
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # Firmware updates — important for Framework (BIOS, EC, fingerprint firmware)
  services.fwupd.enable = true;
}
