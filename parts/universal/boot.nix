{ pkgs, machineConfig, ... }:
{
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    maxGenerations = 10;
    additionalFiles."mt86plus.efi" = "${pkgs.memtest86plus}/mt86plus.efi";
    extraEntries = ''
      /Memtest86+
          protocol: efi
          path: boot():/mt86plus.efi
    '';
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = machineConfig.kernelPackages pkgs;

  # CVE-2026-31431 (copy fail): LPE via algif_aead, not fixed in 6.12 LTS yet
  boot.blacklistedKernelModules = [ "algif_aead" ];
}
