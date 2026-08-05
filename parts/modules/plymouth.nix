{ config, lib, pkgs, ... }:
lib.mkIf (config.host.profile == "desktop") {
  boot.plymouth = {
    enable = true;
    themePackages = [ pkgs.catppuccin-plymouth ];
    theme = "catppuccin-macchiato";
  };
}
