{ config, ... }:
{
  services.caddy.virtualHosts."jellyfin.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8096";

  services.jellyfin = {
    enable = true;
    dataDir = "/tank/services/jellyfin";
    cacheDir = "/tank/services/jellyfin/cache";
    openFirewall = false;
  };

  systemd.services.jellyfin = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
