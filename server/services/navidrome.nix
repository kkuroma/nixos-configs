{ ... }:
{
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
