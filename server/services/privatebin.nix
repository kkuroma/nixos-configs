{ ... }:
{
  services.privatebin.enable = true;

  # privatebin uses nginx internally — restrict to localhost so Caddy can proxy it
  services.nginx.defaultListenAddresses = [ "127.0.0.1" ];
  services.nginx.virtualHosts."localhost".listen = [
    { addr = "127.0.0.1"; port = 8082; ssl = false; }
  ];

  systemd.services.phpfpm-privatebin = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
