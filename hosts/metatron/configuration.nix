{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../parts/universal
    ../../parts/templates
    ../../parts/modules
    ../../parts/services
    ./extra
    ./homepage.nix
  ];

  networking.hostName = "metatron";

  host = {
    gpu = { amd = true; nvidiaCompute = true; };
    desktop = "kde";
    profile = "server";
    features = {
      virtualization = true;
      codiumserver = true;
    };

    services = {
      adguard = {
        enable = true;
        port = 3000;
      };
      jellyfin = {
         enable = true;
         port = 8096;
         dataDir = "/tank/services/jellyfin";
         storage = "zfs";
      };
      navidrome = { 
        enable = true; 
        port = 4533; 
        dataDir = "/tank/services/navidrome";
        storage = "zfs";
      };
      searx= { 
        enable = true; 
        port = 8888; 
        publicHost = "searx.kuroma.dev"; 
      };
      privatebin = { 
        enable = true; 
        port = 8082; 
        publicHost = "pastebin.kuroma.dev"; 
        storage = "zfs"; 
        unit = "phpfpm-privatebin";
      };
      stirling-pdf = { 
        enable = true; 
        port = 8085; 
        publicHost = "pdf.kuroma.dev";
      };
      postgresql = {
        enable = true; 
        dataDir = "/tank/services/postgresql"; 
        storage = "zfs";
      };
      nextcloud = { 
        enable = true;
        port = 8081;
        publicHost = "cloud.kuroma.dev";
        dataDir = "/tank/services/nextcloud";
        storage = "zfs";
        unit = "nextcloud-setup"; 
      };
      matrix = {
        enable = true;
        port = 8448;
        publicHost = "matrix.isomorphic.to";
        publicAuto = false;
        dataDir = "/tank/services/matrix";
        storage = "zfs";
        unit = "matrix-synapse";
      };
      vaultwarden = { 
        enable = true;
        port = 8222;
        publicHost = "vault.kuroma.dev";
        dataDir = "/tank/services/vaultwarden";
        storage = "zfs";
      };
      forgejo = { 
        enable = true; 
        port = 1412; 
        publicHost = "git.kuroma.dev"; 
        dataDir = "/tank/services/forgejo"; 
        storage = "zfs";
      };
    };

    filebrowsers = {
      ct-dump = {
        port = 8200;
        root = "/tank/nas/ct/dump";
        user = "ct";
        group = "family";
      };
    };

    cloudflared.main = {
      tokenSecret = "cloudflared/metatron-token"; # split 2026-07-08: zaphkiel has its own tunnel
      hostnames = [
        "searx.kuroma.dev"
        "pdf.kuroma.dev"
        "pastebin.kuroma.dev"
        "cloud.kuroma.dev"
        "ct-dump.kuroma.dev"
        "public-dump.kuroma.dev"
        "vault.kuroma.dev"
        "git.kuroma.dev"
        "matrix.isomorphic.to"
      ];
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = false; # tailscale0 only via networking.nix
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.hostId = "97c79472"; # head -c8 /etc/machine-id

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" ];
  boot.zfs.unsafeAllowHibernation = true;
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;
  boot.resumeDevice = "/dev/nvme0n1p2";
  boot.kernelParams = [ "resume_offset=533760" ];  # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile

  environment.systemPackages = [ pkgs.firefox ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    monospace = [ "Noto Sans Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };

  system.stateVersion = "25.11";
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 ];
  services.openssh.settings.GatewayPorts = "clientspecified";
}
