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
    ../../modules/caddy.nix
    ../../modules/services.nix
    ../../modules/users.nix
    ../../modules/fcitx5.nix
    ../../modules/sops.nix
    ../../modules/virtualization.nix
    ../../services/syncthing.nix
    ../../services/cockpit.nix
  ];

  networking.hostName = "raziel";

  boot.kernelParams = [
    # s2idle suspend — recommended for Framework 13 AMD
    "mem_sleep_default=s2idle"
    "resume_offset=533760"
    "resume=/dev/mapper/cryptroot"
  ];

  system.stateVersion = "25.11";
}
