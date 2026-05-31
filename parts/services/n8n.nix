{ config, lib, ... }:
let
  cfg = config.host.services.n8n or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."n8n/encryption-key" = {};
  sops.templates."n8n-env" = {
    content = "N8N_ENCRYPTION_KEY=${config.sops.placeholder."n8n/encryption-key"}";
  };

  services.n8n = {
    enable = true;
    environment.GENERIC_TIMEZONE = "Asia/Tokyo";
  };

  systemd.services.n8n = {
    environment.N8N_USER_FOLDER = lib.mkForce cfg.dataDir;
    serviceConfig.ReadWritePaths = [ cfg.dataDir ];
    serviceConfig.EnvironmentFile = config.sops.templates."n8n-env".path;
  };
}
