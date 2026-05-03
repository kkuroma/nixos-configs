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
    fd
    duf
    bottom
    procs
    ffmpeg
    fastfetch
    killall
  ];
}
