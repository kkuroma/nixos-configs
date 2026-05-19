{ config, ... }:
{
  services.caddy.virtualHosts = {
    "searx.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8888";
    "http://searx.kuroma.dev".extraConfig              = "reverse_proxy localhost:8888";
  };

  sops.secrets."searxng/secret-key" = {};
  sops.templates."searx-env" = {
    content = "SEARX_SECRET_KEY=${config.sops.placeholder."searxng/secret-key"}";
  };

  services.searx = {
    enable = true;
    environmentFile = config.sops.templates."searx-env".path;
    settings = {
      server = {
        secret_key = "$SEARX_SECRET_KEY";
        bind_address = "127.0.0.1";
        port = 8888;
      };
      ui.default_theme = "simple";
    };
  };
}
