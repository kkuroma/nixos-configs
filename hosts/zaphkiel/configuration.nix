{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix

    ../../modules/boot.nix
    ../../modules/docker.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ../../modules/niri.nix
    ../../modules/nix.nix
    ../../modules/nvidia.nix
    ../../modules/apps.nix
    ../../modules/autofs.nix
    ../../modules/fonts.nix
    ../../modules/services.nix
    ../../modules/users.nix
    ../../modules/fcitx5.nix
    ../../modules/sops.nix
    ./fstab.nix
  ];

  networking.hostName = "zaphkiel";

  # Hibernate resume — Btrfs swapfile inside LUKS.
  # After first boot: run `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile`
  # and add the printed number as: boot.kernelParams = [ "resume_offset=<NUMBER>" ];
  boot.resumeDevice = "/dev/mapper/cryptroot";

  system.stateVersion = "25.11";
}
