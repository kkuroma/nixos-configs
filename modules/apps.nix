{ pkgs, ... }:
{
  programs.steam.enable = true;

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
    bottom
    procs
    ffmpeg
    fastfetch
    killall
    jq
    lsof
    strace
    file
    xterm
    glfw

    # networking
    nmap
    mtr
    dnsutils
    tcpdump
    whois

    # hardware integration
    pciutils
    usbutils
    nvme-cli    
  ];
}
