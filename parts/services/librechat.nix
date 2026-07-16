{ config, lib, pkgs, metatronIP, ... }:

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
  sops.secrets."librechat/meili-master-key" = { sopsFile = ../../secrets/librechat.yaml; };
  # Same zoho account the metatron mailers (vaultwarden, NUT) use; lives in the shared secrets.yaml.
  sops.secrets."vaultwarden/smtp-password" = { };

  services.librechat = {
    enable = true;
    enableLocalDB = true;
    dataDir = lib.mkIf (cfg.dataDir != null) cfg.dataDir;

    # Conversation/message search. The module wires SEARCH/MEILI_HOST/MEILI_MASTER_KEY
    # + unit ordering itself; it only asks us for the master key file below.
    meilisearch.enable = true;

    credentials = {
      CREDS_KEY = config.sops.secrets."librechat/creds-key".path;
      CREDS_IV = config.sops.secrets."librechat/creds-iv".path;
      JWT_SECRET = config.sops.secrets."librechat/jwt-secret".path;
      JWT_REFRESH_SECRET = config.sops.secrets."librechat/jwt-refresh-secret".path;
      EMAIL_PASSWORD = config.sops.secrets."vaultwarden/smtp-password".path;
    };

    env = {
      HOST = "127.0.0.1";
      PORT = cfg.port;
      DOMAIN_CLIENT = domain;
      DOMAIN_SERVER = domain;
      ALLOW_REGISTRATION = true; # reachable via tailscale/caddy only; disable once accounts exist
      NO_INDEX = true;

      # Password-reset mail via the shared zoho account (password in credentials above).
      ALLOW_PASSWORD_RESET = true;
      EMAIL_HOST = "smtp.zoho.com";
      EMAIL_PORT = 587;
      EMAIL_ENCRYPTION = "starttls";
      EMAIL_USERNAME = "contact@kuroma.dev";
      EMAIL_FROM = "contact@kuroma.dev";
      EMAIL_FROM_NAME = "LibreChat";

      # Web search: metatron's searxng over tailscale (json format + tailscalePorts
      # opened in its service/host config). Non-secret, so a literal env value is fine.
      SEARXNG_INSTANCE_URL = "http://${metatronIP}:8888";
    };

    settings = {
      version = "1.2.1";
      cache = true;

      # Without an explicit allowlist, LibreChat fail-closes on SSRF-prone MCP
      # targets — which includes loopback. Entries match protocol://host:port.
      mcpSettings.allowedDomains = lib.mkIf graphiv.enable [
        "http://127.0.0.1:${toString graphiv.port}"
      ];

      # Provider comes from SEARXNG_INSTANCE_URL above. A scraper (firecrawl/tavily)
      # is still required per search — no self-hosted one yet, so users paste their
      # own key in the UI dialog until firecrawl is wired. Reranking off.
      webSearch = {
        searchProvider = "searxng";
        rerankerType = "none";
      };

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

  # Read via LoadCredential (root) by both meilisearch and librechat.
  services.meilisearch.masterKeyFile = config.sops.secrets."librechat/meili-master-key".path;
  # Keep the index next to librechat's state when the host moves it off /var
  # (module default is /var/lib/meilisearch). Index is disposable — librechat
  # re-syncs it from mongo on startup.
  services.meilisearch.settings = lib.mkIf (cfg.dataDir != null) {
    db_path = "${dirOf cfg.dataDir}/meilisearch";
    dump_dir = "${dirOf cfg.dataDir}/meilisearch/dumps";
    snapshot_dir = "${dirOf cfg.dataDir}/meilisearch/snapshots";
  };
  # The module's DynamicUser can't own dirs outside /var/lib — pin a static user.
  users.users.meilisearch = lib.mkIf (cfg.dataDir != null) {
    isSystemUser = true;
    group = "meilisearch";
  };
  users.groups.meilisearch = lib.mkIf (cfg.dataDir != null) { };
  systemd.tmpfiles.rules = lib.mkIf (cfg.dataDir != null) [
    "d ${dirOf cfg.dataDir}/meilisearch 0700 meilisearch meilisearch -"
  ];
  systemd.services.meilisearch = {
    serviceConfig = lib.mkIf (cfg.dataDir != null) {
      DynamicUser = lib.mkForce false;
      User = "meilisearch";
      Group = "meilisearch";
    };
    after = lib.mkIf (cfg.storage == "vault") [ "Vault.mount" ];
    requires = lib.mkIf (cfg.storage == "vault") [ "Vault.mount" ];
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
