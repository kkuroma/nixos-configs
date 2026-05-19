{ config, ... }:
{
  services.caddy.virtualHosts = {
    "vaultwarden.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8222";
    "http://vault.kuroma.dev".extraConfig = "reverse_proxy localhost:8222";
  };

  sops.secrets."vaultwarden/admin-token" = { owner = "vaultwarden"; };

  sops.templates."vaultwarden-env" = {
    content = ''
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
    '';
    owner = "vaultwarden";
  };

  systemd.services.vaultwarden = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.templates."vaultwarden-env".path;
    config = {
      DOMAIN = "https://vault.kuroma.dev";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      DATA_FOLDER = "/tank/services/vaultwarden";
    };
  };
}
