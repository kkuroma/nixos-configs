{ config, ... }:
{
  services.caddy.virtualHosts."neo4j.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:7474";

  sops.secrets."neo4j/password" = {};

  services.neo4j = {
    enable = true;
    https.enable = false;
    http.enable = true;
    directories.home = "/Vault/neo4j";
  };

  systemd.services.neo4j = {
    after    = [ "Vault.mount" ];
    requires = [ "Vault.mount" ];
  };
}
