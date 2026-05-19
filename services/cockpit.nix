{ config, lib, ... }:
{
  services.caddy.virtualHosts."cockpit.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:9090";

  services.cockpit = {
    enable = true;
    settings.WebService = {
      AllowUnencrypted = "true";
      Origins = lib.mkForce "https://cockpit.${config.networking.hostName}";
    };
  };

  security.pam.services.cockpit = {};
}
