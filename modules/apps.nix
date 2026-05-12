{ pkgs, inputs, ... }:
{
  services.envfs.enable = true; # symlinks /bin stuff to scripts
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  # millenium steam for custom colors
  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
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
