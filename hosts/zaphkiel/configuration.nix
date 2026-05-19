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
    ../../modules/caddy.nix
    ../../modules/services.nix
    ../../modules/users.nix
    ../../modules/fcitx5.nix
    ../../modules/sops.nix
    ../../modules/virtualization.nix
    ../../modules/codiumserver.nix
    ../../services/syncthing.nix
    ../../services/cockpit.nix
    ../../services/n8n.nix
    ../../services/neo4j.nix
    ../../services/llama.nix
    ./backup.nix
  ];

  networking.hostName = "zaphkiel";
  # networking.firewall.allowedTCPPorts = [ add temporary ports here, was 3000 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 11435 7687 ]; # llama API + neo4j bolt (n8n/neo4j-http via caddy)
  boot.kernelParams = [ 
    "resume_offset=92872541" 
    "resume=/dev/mapper/cryptroot"
  ];
  system.stateVersion = "25.11";
}
