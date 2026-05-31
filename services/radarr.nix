{ config, lib, ... }:
let
  cfg = config.host.services.radarr or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  services.radarr = {
    enable = true;
    dataDir = cfg.dataDir;
    user = "kuroma";
    group = "users";
  };

  systemd.services.radarr.after = [ "autofs.service" ];
}
