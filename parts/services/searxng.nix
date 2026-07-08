{ config, lib, ... }:
let
  cfg = config.host.services.searxng or null;
in
lib.mkIf (cfg != null && cfg.enable) {
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
        port = cfg.port;
      };
      ui.default_theme = "simple";
    };
  };
}
