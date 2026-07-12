{ config, lib, pkgs, ... }:

# LibreChat via the nixpkgs module: local llama-router as the only model endpoint,
# GraphIV MCP attached over streamable-http (the module's ProtectHome sandbox can't
# spawn a stdio server living in /home). Mongo via enableLocalDB, switched to the
# prebuilt mongodb-ce (stock pkgs.mongodb is an hours-long source build).
let
  cfg = config.host.services.librechat or null;
  graphiv = config.host.services.graphiv or { enable = false; port = 8756; };
  llama = config.host.services.llama or { enable = false; port = 11434; };
  domain = "https://librechat.${config.networking.hostName}";
in
lib.mkIf (cfg != null && cfg.enable) {
  # secrets/librechat.yaml is its own sops file (encrypted to the same recipients).
  sops.secrets."librechat/creds-key" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/creds-iv" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/jwt-secret" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/jwt-refresh-secret" = { sopsFile = ../../secrets/librechat.yaml; };

  services.librechat = {
    enable = true;
    enableLocalDB = true;
    dataDir = lib.mkIf (cfg.dataDir != null) cfg.dataDir;

    credentials = {
      CREDS_KEY = config.sops.secrets."librechat/creds-key".path;
      CREDS_IV = config.sops.secrets."librechat/creds-iv".path;
      JWT_SECRET = config.sops.secrets."librechat/jwt-secret".path;
      JWT_REFRESH_SECRET = config.sops.secrets."librechat/jwt-refresh-secret".path;
    };

    env = {
      HOST = "127.0.0.1";
      PORT = cfg.port;
      DOMAIN_CLIENT = domain;
      DOMAIN_SERVER = domain;
      ALLOW_REGISTRATION = true; # reachable via tailscale/caddy only; disable once accounts exist
      NO_INDEX = true;
    };

    settings = {
      version = "1.2.1";
      cache = true;

      # Without an explicit allowlist, LibreChat fail-closes on SSRF-prone MCP
      # targets — which includes loopback. Entries match protocol://host:port.
      mcpSettings.allowedDomains = lib.mkIf graphiv.enable [
        "http://127.0.0.1:${toString graphiv.port}"
      ];

      endpoints.custom = [
        {
          name = "llama-router";
          apiKey = "sk-local"; # router does no auth; the field is mandatory
          baseURL = "http://localhost:${toString llama.port}/v1";
          # -Code preset: parallel=1 -> full 131072 ctx (plain 26B is 32k/slot; two
          # deep_research outputs overflow it). titleModel matches to avoid a swap.
          models = {
            default = [ "Gemma-4-26B-Code" ];
            fetch = true;
          };
          titleConvo = true;
          titleModel = "Gemma-4-26B-Code";
          modelDisplayLabel = "llama-router";
        }
      ];

      mcpServers = lib.optionalAttrs graphiv.enable {
        graphiv = {
          type = "streamable-http";
          url = "http://127.0.0.1:${toString graphiv.port}/mcp";
          timeout = 7200000; # ms — deep_research holds the tool call up to 2 h
          initTimeout = 30000;
        };
      };
    };
  };

  services.mongodb.package = pkgs.mongodb-ce;
  # Keep mongo state next to librechat's when the host moves it off /var.
  services.mongodb.dbpath = lib.mkIf (cfg.dataDir != null) "${dirOf cfg.dataDir}/mongodb";
  # The host.services glue orders only cfg.unit (librechat) on the storage mount.
  systemd.services.mongodb = lib.mkIf (cfg.storage == "vault") {
    after = [ "Vault.mount" ];
    requires = [ "Vault.mount" ];
  };
}
