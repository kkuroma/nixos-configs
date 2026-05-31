{ config, lib, ... }:
lib.mkIf (config.host.desktop == "kde") {
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
}
