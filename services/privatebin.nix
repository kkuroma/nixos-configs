{ config, ... }:
{
  services.caddy.virtualHosts = {
    "pastebin.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8082";
    "http://pastebin.kuroma.dev".extraConfig             = "reverse_proxy localhost:8082";
  };

  services.privatebin = {
    enable = true;
    enableNginx = true;
  };

  services.nginx.virtualHosts."localhost".listen = [
    { addr = "127.0.0.1"; port = 8082; ssl = false; }
  ];

  systemd.services.phpfpm-privatebin = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
