{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
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
    ../../modules/virtualization.nix
    ../../modules/codiumserver.nix
    ./ai-services.nix
    ./backup.nix
  ];

  networking.hostName = "zaphkiel";
  networking.firewall.allowedTCPPorts = [ 3000 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 11435 ];
  boot.kernelParams = [ 
    "resume_offset=92872541" 
    "resume=/dev/mapper/cryptroot"
  ];
  system.stateVersion = "25.11";
}
