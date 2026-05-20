{ config, ... }:
{
  services.glances = {
    enable = true;
    port = 61208;
  };

  services.caddy.virtualHosts."glances.${config.networking.hostName}".extraConfig = ''
    tls internal
    reverse_proxy localhost:61208
  '';
}
