{ config, lib, ... }:
{
  services.caddy.virtualHosts."n8n.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:5678";

  sops.secrets."n8n/encryption-key" = {};
  sops.templates."n8n-env" = {
    content = "N8N_ENCRYPTION_KEY=${config.sops.placeholder."n8n/encryption-key"}";
  };

  services.n8n = {
    enable = true;
    environment.GENERIC_TIMEZONE = "Asia/Tokyo";
  };

  systemd.services.n8n = {
    after    = [ "Vault.mount" ];
    requires = [ "Vault.mount" ];
    environment.N8N_USER_FOLDER = lib.mkForce "/Vault/n8n";
    serviceConfig.ReadWritePaths = [ "/Vault/n8n" ];
  };
  systemd.services.n8n.serviceConfig.EnvironmentFile = config.sops.templates."n8n-env".path;
}
