{ config, lib, ... }:
# Flatpak runtime + portals — currently only needed by the 3d-printing bundle (BambuStudio).
# App list lives in home/3d-printing.nix.
lib.mkIf config.host.home."3d-printing" {
  services.flatpak.enable = true;
}
