{ config, ... }:
{
  services.caddy.virtualHosts."sonarr.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8989";

  services.sonarr = {
    enable = true;
    dataDir = "/Vault/sonarr";
    user = "kuroma";
    group = "users";
  };

  systemd.services.sonarr = {
    after = [ "Vault.mount" "autofs.service" ];
    requires = [ "Vault.mount" ];
  };
}
