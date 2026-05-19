{ config, ... }:
{
  services.caddy.virtualHosts."navidrome.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:4533";

  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/tank/media/music";
      DataFolder = "/tank/services/navidrome";
      Address = "127.0.0.1";
      Port = 4533;
    };
  };

  systemd.services.navidrome = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
