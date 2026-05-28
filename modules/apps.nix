{ pkgs, inputs, ... }:
{
  services.envfs.enable = true; # symlinks /bin stuff to scripts

  # millenium steam for custom colors
  programs.steam = {
    enable = true;
  };

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
    xterm
    glfw
    zellij

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
