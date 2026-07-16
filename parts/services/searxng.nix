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
        # 0.0.0.0 so API consumers on other hosts (librechat web search) can reach it
        # directly; firewall only opens the port on tailscale0 via tailscalePorts.
        bind_address = "0.0.0.0";
        port = cfg.port;
      };
      # json needed for API consumers (librechat) — searx 403s format=json otherwise
      search.formats = [ "html" "json" ];
      ui.default_theme = "simple";
    };
  };
}
