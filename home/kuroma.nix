{ inputs, pkgs, ... }:
{
  imports = [ ./niri.nix ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";
}
