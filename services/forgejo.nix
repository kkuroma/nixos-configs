{ config, ... }:
{
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

  systemd.services.forgejo = {
    after = [ "zfs-datasets.service" "postgresql-setup.service" ];
    requires = [ "zfs-datasets.service" "postgresql-setup.service" ];
  };

  # git SSH on port 2222, tailscale only
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2222 ];
}
