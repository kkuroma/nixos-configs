{ config, ... }:
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
  systemd.services.n8n.serviceConfig.EnvironmentFile = config.sops.templates."n8n-env".path;
}
