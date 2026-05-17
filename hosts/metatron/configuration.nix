{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./fstab.nix

    ../../modules/boot.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/amd.nix # Radeon 740M iGPU display + vaapi
    ../../modules/fonts.nix
    ../../modules/users.nix
    ../../modules/sops.nix
    ../../modules/codiumserver.nix
    ../../modules/kde.nix
    ../../modules/nvidia-compute.nix  # GTX 1650 headless CUDA
    ../../modules/virtualization.nix
  ];

  networking.hostName = "metatron";

  # ZFS requires a unique hostId — generate with: head -c8 /etc/machine-id
  networking.hostId = "00000000"; # TODO: fill after first boot

  boot.supportedFilesystems = [ "zfs" ];
  # Data pool on sda–sdd RAIDZ1 — import post-install after: zpool create tank raidz sda sdb sdc sdd
  boot.zfs.extraPools = [ "tank" ];

  # Hibernate resume — fill resume_offset after install:
  # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  boot.resumeDevice = "/dev/mapper/cryptroot";
  boot.kernelParams = [
    "resume_offset=0" # TODO: set after first boot
  ];

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

  system.stateVersion = "25.11";
}
