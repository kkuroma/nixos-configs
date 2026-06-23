{ config, lib, ... }:
# Flatpak runtime + portals. App list lives in home/flatpak.nix.
lib.mkIf config.host.home.flatpak {
  services.flatpak.enable = true;
}
