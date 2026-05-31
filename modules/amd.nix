{ pkgs, config, lib, ... }:
lib.mkIf config.host.gpu.amd {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # active = EPP-based; power-profiles-daemon sends EPP hints directly to the driver
  boot.kernelParams = [ "amd_pstate=active" ];

  environment.systemPackages = [ pkgs.ryzenadj ];

  services.lact.enable = true;
}
