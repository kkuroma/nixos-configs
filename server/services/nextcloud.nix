{ pkgs, config, ... }:
{
  sops.secrets."nextcloud/admin-password" = { owner = "nextcloud"; };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "nextcloud.metatron";
    datadir = "/tank/services/nextcloud";
    database.createLocally = true;
    config = {
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      adminuser = "admin";
      dbtype = "pgsql";
    };
    settings = {
      trusted_domains = [ "nextcloud.metatron" "cloud.kuroma.dev" ];
      trusted_proxies = [ "127.0.0.1" "::1" ];
      overwriteprotocol = "https";
    };
  };

  services.nginx.virtualHosts."nextcloud.metatron".listen = [
    { addr = "127.0.0.1"; port = 8081; ssl = false; }
  ];

  systemd.services.nextcloud-setup = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
