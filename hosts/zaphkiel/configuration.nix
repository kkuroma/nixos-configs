{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./virtualization.nix
    ./fstab.nix

    ../../modules/boot.nix
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
  ];

  networking.hostName = "zaphkiel";
  boot.kernelParams = [ 
    "resume_offset=533760" 
    "resume=/dev/mapper/cryptroot"
  ];
  system.stateVersion = "25.11";
}
