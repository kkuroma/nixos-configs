{ pkgs, config, ... }:
let
  btop-gpu = pkgs.btop.override {
    cudaSupport = config.host.gpu.nvidia || config.host.gpu.nvidiaCompute;
    rocmSupport = config.host.gpu.amd;
  };
in
{
  # Base toolkit, every host gets these regardless of profile.
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
    btop-gpu
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
