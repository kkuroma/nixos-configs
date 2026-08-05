{ lib, pkgs, machineConfig, ... }:
let
  theme = builtins.readFile ../../config/limine/catppuccin-macchiato-mauve.conf;
  directive =
    key:
    lib.removePrefix "${key}: " (
      lib.findFirst (l: lib.hasPrefix "${key}: " l) null (lib.splitString "\n" theme)
    );
in
{
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    maxGenerations = 10;
    extraConfig = theme;
    style.wallpapers = [ ];
    style.backdrop = directive "term_background";
    additionalFiles."mt86plus.efi" = "${pkgs.memtest86plus}/mt86plus.efi";
    extraEntries = ''
      /Memtest86+
          protocol: efi
          path: boot():/mt86plus.efi
    '';
  };

  console.earlySetup = true;
  console.colors =
    lib.splitString ";" (directive "term_palette")
    ++ lib.splitString ";" (directive "term_palette_bright");

  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = machineConfig.kernelPackages pkgs;

  # CVE-2026-31431 (copy fail): LPE via algif_aead, not fixed in 6.12 LTS yet
  boot.blacklistedKernelModules = [ "algif_aead" ];
}
