{ config, lib, ... }:
# Currently just has 3d printing
lib.mkIf config.host.home."3d-printing" {
  services.flatpak.enable = true;
}
