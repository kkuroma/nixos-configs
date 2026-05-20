{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./fstab.nix

    ./nas/datasets.nix
    ./nas/smb.nix

    ../../modules/boot.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/amd.nix # Radeon 740M iGPU display + vaapi
    ../../modules/users.nix
    ../../modules/sops.nix
    ../../modules/codiumserver.nix
    ../../modules/kde.nix
    ../../modules/nvidia-compute.nix  # GTX 1650 headless CUDA
    ../../modules/virtualization.nix
    ../../modules/caddy.nix

    ../../services/adguardhome.nix
    ../../services/jellyfin.nix
    ../../services/navidrome.nix
    ../../services/searxng.nix
    ../../services/privatebin.nix
    ../../services/stirling-pdf.nix
    ./cloudflared.nix
    ../../services/postgresql.nix
    ../../services/nextcloud.nix
    ../../services/matrix.nix
    ../../services/filebrowser.nix
    ../../services/vaultwarden.nix
    ../../services/forgejo.nix
    ../../services/glances.nix
    ../../services/homepage.nix
  ];

  networking.hostName = "metatron";

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

  boot.zfs.allowHibernation = true;
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;
  boot.resumeDevice = "/dev/nvme0n1p2";
  boot.kernelParams = [ "resume_offset=533760" ];  # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile

  environment.systemPackages = with pkgs; [
    firefox

    # core CLI
    nushell
    git
    wget
    curl
    zip
    unzip

    # CLI tools
    ripgrep
    tree
    fd
    duf
    dust
    btop
    procs
    ffmpeg
    killall
    jq
    lsof
    strace
    file
    zellij

    # networking / diagnostics
    nmap
    mtr
    dnsutils
    tcpdump
    whois

    # hardware
    pciutils
    usbutils
    nvme-cli
    smartmontools
  ];

  # NFS/SMB service users — no shell, no interactive login, UID/GID for ACL.
  # Add per-person and per-service users here post-install, e.g.:
  # users.users.alice = { uid = 1001; isSystemUser = true; group = "users"; };

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
