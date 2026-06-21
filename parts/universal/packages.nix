{ pkgs, ... }:
{
  # Base toolkit — every host gets these regardless of profile.
  environment.systemPackages = with pkgs; [
    # core
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
    sqlite
    lsd
    bat
    jq
    curl

    # networking
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
    gparted
  ];
}
