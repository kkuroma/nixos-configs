{ pkgs, ... }:
{
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # active = EPP-based; power-profiles-daemon sends EPP hints directly to the driver
  boot.kernelParams = [ "amd_pstate=active" ];

  environment.systemPackages = [ pkgs.ryzenadj amd-xdna-driver-libs];

  services.lact.enable = true;
}
