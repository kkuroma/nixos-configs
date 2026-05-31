{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./fstab.nix

    ./nas/datasets.nix
    ./nas/smb.nix

    ../../templates
    ../../modules
    ../../services

    ./cloudflared.nix
    ./homepage.nix
    ./nut.nix
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
      adguardhome  = { enable = true; port = 3000; };
      jellyfin     = { enable = true; port = 8096; dataDir = "/tank/services/jellyfin"; storage = "zfs"; };
      navidrome    = { enable = true; port = 4533; dataDir = "/tank/services/navidrome"; storage = "zfs"; };
      searx        = { enable = true; port = 8888; publicHost = "searx.kuroma.dev"; };
      privatebin   = { enable = true; port = 8082; publicHost = "pastebin.kuroma.dev"; storage = "zfs"; unit = "phpfpm-privatebin"; };
      stirling-pdf = { enable = true; port = 8085; publicHost = "pdf.kuroma.dev"; };
      postgresql   = { enable = true; dataDir = "/tank/services/postgresql"; storage = "zfs"; };
      nextcloud    = { enable = true; port = 8081; publicHost = "cloud.kuroma.dev"; dataDir = "/tank/services/nextcloud"; storage = "zfs"; unit = "nextcloud-setup"; };
      matrix       = { enable = true; port = 8448; publicHost = "matrix.isomorphic.to"; publicAuto = false; dataDir = "/tank/services/matrix"; storage = "zfs"; unit = "matrix-synapse"; };
      vaultwarden  = { enable = true; port = 8222; publicHost = "vault.kuroma.dev"; dataDir = "/tank/services/vaultwarden"; storage = "zfs"; };
      forgejo      = { enable = true; port = 1412; publicHost = "git.kuroma.dev"; dataDir = "/tank/services/forgejo"; storage = "zfs"; };
    };

    filebrowsers.ct-dump = {
      port = 8200;
      root = "/tank/nas/ct/dump";
      user = "ct";
      group = "family";
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
}
