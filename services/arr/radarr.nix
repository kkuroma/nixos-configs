{ config, ... }:
{
  services.caddy.virtualHosts."radarr.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:7878";

  services.radarr = {
    enable = true;
    dataDir = "/Vault/radarr";
    user = "kuroma";
    group = "users";
  };

  systemd.services.radarr = {
    after = [ "Vault.mount" "autofs.service" ];
    requires = [ "Vault.mount" ];
  };
}
