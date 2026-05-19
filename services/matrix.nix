{ lib, config, ... }:
{
  services.caddy.virtualHosts = {
    "matrix.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8448";
    "http://matrix.isomorphic.to".extraConfig = ''
      handle /.well-known/matrix/server {
        header Content-Type application/json
        respond `{"m.server":"matrix.isomorphic.to:443"}` 200
      }
      handle /.well-known/matrix/client {
        header Content-Type application/json
        header Access-Control-Allow-Origin *
        respond `{"m.homeserver":{"base_url":"https://matrix.isomorphic.to"}}` 200
      }
      handle {
        reverse_proxy localhost:8448
      }
    '';
  };

  sops.secrets."matrix/registration-secret" = { owner = "matrix-synapse"; };
  sops.secrets."matrix/macaroon-secret" = { owner = "matrix-synapse"; };
  sops.secrets."matrix/form-secret" = { owner = "matrix-synapse"; };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = "matrix.isomorphic.to";
      public_baseurl = "https://matrix.isomorphic.to";

      database = {
        name = "psycopg2";
        args = {
          database = "matrix-synapse";
          host = "/run/postgresql";
          cp_min = 5;
          cp_max = 10;
        };
      };

      listeners = [{
        port = 8448;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        resources = [{
          names = [ "client" "federation" ];
          compress = false;
        }];
      }];

      enable_registration = false;
      registration_shared_secret_path = config.sops.secrets."matrix/registration-secret".path;
      macaroon_secret_key_path = config.sops.secrets."matrix/macaroon-secret".path;
      form_secret_path = config.sops.secrets."matrix/form-secret".path;
      media_store_path = "/tank/services/matrix/media";
    };
  };

  services.postgresql.ensureUsers = [{
    name = "matrix-synapse";
  }];

  # Synapse requires LC_COLLATE=C; ensureDatabases doesn't support collation
  systemd.services.postgresql.postStart = lib.mkAfter ''
    psql -tAc "SELECT 1 FROM pg_database WHERE datname='matrix-synapse'" | grep -q 1 || psql -tAc "CREATE DATABASE \"matrix-synapse\" WITH OWNER=\"matrix-synapse\" TEMPLATE=template0 LC_COLLATE='C' LC_CTYPE='C' ENCODING='UTF8'"
  '';

  systemd.tmpfiles.rules = [
    "d /tank/services/matrix/media 0700 matrix-synapse matrix-synapse -"
    "z /tank/services/matrix/media 0700 matrix-synapse matrix-synapse -"
  ];

  systemd.services.matrix-synapse = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
