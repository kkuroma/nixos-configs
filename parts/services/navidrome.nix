{ config, lib, ... }:
let
  cfg = config.host.services.navidrome or null;
in
{
  services.navidrome = lib.mkIf (cfg != null && cfg.enable) {
    enable = true;
    settings = {
      MusicFolder = "/tank/media/music";
      DataFolder = cfg.dataDir;
      Address = "127.0.0.1";
      Port = cfg.port;
    };
  };
}
