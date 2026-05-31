{ pkgs, config, lib, ... }:
let
  cfg = config.host.services.nextcloud or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."nextcloud/admin-password" = { owner = "nextcloud"; };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "nextcloud.${config.networking.hostName}";
    datadir = cfg.dataDir;
    database.createLocally = true;
    config = {
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      adminuser = "admin";
      dbtype = "pgsql";
    };
    settings = {
      trusted_domains = [ "nextcloud.${config.networking.hostName}" cfg.publicHost ];
      trusted_proxies = [ "127.0.0.1" "::1" ];
      overwriteprotocol = "https";
    };
  };

  services.nginx.virtualHosts."nextcloud.${config.networking.hostName}".listen = [
    { addr = "127.0.0.1"; port = cfg.port; ssl = false; }
  ];

  # Fix ownership of subdirs that systemd-tmpfiles may create as root before zfs-datasets chowns the mountpoint
  systemd.tmpfiles.rules = [
    "z ${cfg.dataDir}         0700 nextcloud nextcloud -"
    "z ${cfg.dataDir}/config  0750 nextcloud nextcloud -"
    "z ${cfg.dataDir}/data    0750 nextcloud nextcloud -"
    "z ${cfg.dataDir}/apps    0750 nextcloud nextcloud -"
  ];

  systemd.services.nextcloud-setup = {
    after = [ "systemd-tmpfiles-setup.service" "postgresql-setup.service" ];
    requires = [ "postgresql-setup.service" ];
  };
}
