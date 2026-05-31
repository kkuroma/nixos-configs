{ config, lib, ... }:
let
  cfg = config.host.services.privatebin or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  services.privatebin = {
    enable = true;
    enableNginx = true;
  };

  services.nginx.virtualHosts."localhost".listen = [
    { addr = "127.0.0.1"; port = cfg.port; ssl = false; }
  ];
}
