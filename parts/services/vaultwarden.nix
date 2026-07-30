{ config, lib, ... }:
let
  cfg = config.host.services.vaultwarden or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."vaultwarden/admin-token" = { owner = "vaultwarden"; };
  sops.secrets."vaultwarden/smtp-password" = { owner = "vaultwarden"; };

  sops.templates."vaultwarden-env" = {
    content = ''
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
      SMTP_PASSWORD=${config.sops.placeholder."vaultwarden/smtp-password"}
    '';
    owner = "vaultwarden";
  };

  systemd.services.vaultwarden.serviceConfig.ReadWritePaths = [ cfg.dataDir ];

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.templates."vaultwarden-env".path;
    config = {
      DOMAIN = "https://${cfg.publicHost}";
      ROCKET_PORT = cfg.port;
      SIGNUPS_ALLOWED = false;
      DATA_FOLDER = cfg.dataDir;
      SMTP_HOST = "smtp.zoho.com";
      SMTP_PORT = 587;
      SMTP_SECURITY = "starttls";
      SMTP_USERNAME = "contact@kuroma.dev";
      SMTP_FROM = "contact@kuroma.dev";
      SMTP_FROM_NAME = "Vaultwarden";
    };
  };
}
