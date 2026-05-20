{ config, lib, pkgs, ... }:
{
  sops.secrets."forgejo/secret-key" = { owner = "forgejo"; };
  sops.secrets."forgejo/internal-token" = { owner = "forgejo"; };
  sops.secrets."forgejo/oauth2-jwt-secret" = { owner = "forgejo"; };

  services.caddy.virtualHosts = {
    "forgejo.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:1412";
    "http://git.kuroma.dev".extraConfig = "reverse_proxy localhost:1412";
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
        HTTP_PORT = 1412;
        SSH_PORT = 2222;
        SSH_DOMAIN = "metatron";
      };
      actions.ENABLED = true;
    };
  };

  # forgejo-secrets.service only writes if files are empty — sops secrets never are,
  # so it's a no-op. Clear ReadWritePaths so it doesn't need customDir to exist first.
  systemd.services.forgejo-secrets = {
    after = [ "sops-install-secrets.service" ];
    serviceConfig.ReadWritePaths = lib.mkForce [];
  };

  # Create custom/conf dirs on ZFS after dataset is mounted
  systemd.services.forgejo-init-dirs = {
    description = "Create Forgejo directory structure on ZFS";
    after = [ "zfs-datasets.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/install -d -m 750 -o forgejo -g forgejo /tank/services/forgejo/custom /tank/services/forgejo/custom/conf";
    };
  };

  systemd.services.forgejo = {
    after = [ "zfs-datasets.service" "postgresql-setup.service" "forgejo-init-dirs.service" ];
    requires = [ "zfs-datasets.service" "postgresql-setup.service" "forgejo-init-dirs.service" ];
    # Forgejo 11.x writes to app.ini on startup (oauth2 init); the pre-start sets
    # it read-only after injecting secrets, so we re-enable writes before ExecStart.
    serviceConfig.ExecStartPre = lib.mkAfter [
      "+${pkgs.coreutils}/bin/chmod u+w /tank/services/forgejo/custom/conf/app.ini"
    ];
  };

  # git SSH on port 2222, tailscale only
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2222 ];
}
