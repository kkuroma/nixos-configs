{ config, ... }:
{
  sops.secrets."searx/secret-key" = {};
  sops.templates."searx-env" = {
    content = "SEARX_SECRET_KEY=${config.sops.placeholder."searx/secret-key"}";
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
