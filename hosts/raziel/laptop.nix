{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.fw-ectool ];

  services.udev.packages = [ pkgs.brightnessctl ];

  services.logind.settings.Login.HandlePowerKey = "ignore";

  # fprintd enabled by nixos-hardware; 27c6:609c is natively supported in libfprint 1.94+,
  # the TOD driver (0.0.6, designed for 53xc) uses wrong delete protocol and breaks re-enrollment
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;
  services.fwupd.enable = true;
}
