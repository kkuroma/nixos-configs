{ ... }:
{
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
