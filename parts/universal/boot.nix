{ pkgs, machineConfig, ... }:
{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = machineConfig.kernelPackages pkgs;

  # CVE-2026-31431 (copy fail) — LPE via algif_aead, not fixed in 6.12 LTS yet
  boot.blacklistedKernelModules = [ "algif_aead" ];
}
