{ pkgs, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    nushell
    git
    wget
    curl
    zip
    unzip
  ];
}
