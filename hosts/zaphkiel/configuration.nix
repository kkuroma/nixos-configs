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
  ];

  networking.hostName = "zaphkiel";

  system.stateVersion = "25.11";
}
