{ config, lib, ... }:
let
  cfg = config.host.services.jellyfin or null;
in
{
  services.jellyfin = lib.mkIf (cfg != null && cfg.enable) {
    enable = true;
    dataDir = cfg.dataDir;
    cacheDir = "${cfg.dataDir}/cache";
    openFirewall = false;
  };
}
