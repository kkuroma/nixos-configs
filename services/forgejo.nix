{ config, lib, ... }:
{
  sops.secrets."forgejo/secret-key" = { owner = "forgejo"; };
  sops.secrets."forgejo/internal-token" = { owner = "forgejo"; };
  sops.secrets."forgejo/oauth2-jwt-secret" = { owner = "forgejo"; };

  services.caddy.virtualHosts = {
    "forgejo.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:3000";
    "http://git.kuroma.dev".extraConfig = "reverse_proxy localhost:3000";
  };

  services.forgejo = {
    enable = true;
    stateDir = "/tank/services/forgejo";
    database = {
      type = "postgres";
      createDatabase = true;
    };
    secrets = {
      security = {
        SECRET_KEY = lib.mkForce config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = lib.mkForce config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
    };
    settings = {
      server = {
        DOMAIN = "git.kuroma.dev";
        ROOT_URL = "https://git.kuroma.dev";
        HTTP_PORT = 3000;
        SSH_PORT = 2222;
        SSH_DOMAIN = "metatron";
      };
    };
  };

  # forgejo-secrets.service generates secrets if missing — needs zfs + sops first
  systemd.services.forgejo-secrets = {
    after = [ "zfs-datasets.service" "sops-install-secrets.service" ];
    requires = [ "zfs-datasets.service" ];
  };

  systemd.services.forgejo = {
    after = [ "zfs-datasets.service" "postgresql-setup.service" ];
    requires = [ "zfs-datasets.service" "postgresql-setup.service" ];
  };

  # git SSH on port 2222, tailscale only
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2222 ];
}
