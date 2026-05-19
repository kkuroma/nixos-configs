{ pkgs, config, ... }:
{
  services.caddy.virtualHosts = {
    "nextcloud.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8081";
    "http://cloud.kuroma.dev".extraConfig                 = "reverse_proxy localhost:8081";
  };

  sops.secrets."nextcloud/admin-password" = { owner = "nextcloud"; };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "nextcloud.${config.networking.hostName}";
    datadir = "/tank/services/nextcloud";
    database.createLocally = true;
    config = {
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      adminuser = "admin";
      dbtype = "pgsql";
    };
    settings = {
      trusted_domains = [ "nextcloud.${config.networking.hostName}" "cloud.kuroma.dev" ];
      trusted_proxies = [ "127.0.0.1" "::1" ];
      overwriteprotocol = "https";
    };
  };

  services.nginx.virtualHosts."nextcloud.${config.networking.hostName}".listen = [
    { addr = "127.0.0.1"; port = 8081; ssl = false; }
  ];

  # Fix ownership of subdirs that systemd-tmpfiles may create as root before zfs-datasets chowns the mountpoint
  systemd.tmpfiles.rules = [
    "z /tank/services/nextcloud         0700 nextcloud nextcloud -"
    "z /tank/services/nextcloud/config  0750 nextcloud nextcloud -"
    "z /tank/services/nextcloud/data    0750 nextcloud nextcloud -"
    "z /tank/services/nextcloud/apps    0750 nextcloud nextcloud -"
  ];

  systemd.services.nextcloud-setup = {
    after = [ "zfs-datasets.service" "systemd-tmpfiles-setup.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
