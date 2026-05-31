{ config, lib, ... }:
let
  cfg = config.host.services.sonarr or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  services.sonarr = {
    enable = true;
    dataDir = cfg.dataDir;
    user = "kuroma";
    group = "users";
  };

  systemd.services.sonarr.after = [ "autofs.service" ];
}
