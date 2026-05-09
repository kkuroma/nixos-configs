{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./fstab.nix
    ./laptop.nix

    ../../modules/boot.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ../../modules/niri.nix
    ../../modules/nix.nix
    ../../modules/amd.nix
    ../../modules/apps.nix
    ../../modules/autofs.nix
    ../../modules/fonts.nix
    ../../modules/services.nix
    ../../modules/users.nix
    ../../modules/fcitx5.nix
    ../../modules/sops.nix
    ../../modules/virtualization.nix
  ];

  networking.hostName = "raziel";

  boot.kernelParams = [
    # s2idle suspend — recommended for Framework 13 AMD
    "mem_sleep_default=s2idle"
    # Fill in after install: sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
    # "resume_offset=XXXXXXXX"
    # "resume=/dev/mapper/cryptroot"
  ];

  system.stateVersion = "25.11";
}
