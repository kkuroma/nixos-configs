{ config, lib, pkgs, ... }:

# LibreChat via the nixpkgs module: local llama-router as the only model endpoint
let
  cfg = config.host.services.librechat or null;
  graphiv = config.host.services.graphiv or { enable = false; port = 8756; };
  llama = config.host.services.llama or { enable = false; port = 11434; };
  domain = "https://librechat.${config.networking.hostName}";
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."librechat/creds-key" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/creds-iv" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/jwt-secret" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/jwt-refresh-secret" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."librechat/meili-master-key" = { sopsFile = ../../secrets/librechat.yaml; };
  sops.secrets."vaultwarden/smtp-password" = { };

  services.librechat = {
    enable = true;
    enableLocalDB = true;
    dataDir = lib.mkIf (cfg.dataDir != null) cfg.dataDir;

    meilisearch.enable = true; # chat history search

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

      # Password-reset mail via the shared zoho account (password in credentials above)
      ALLOW_PASSWORD_RESET = true;
      EMAIL_HOST = "smtp.zoho.com";
      EMAIL_PORT = 587;
      EMAIL_ENCRYPTION = "starttls";
      EMAIL_USERNAME = "contact@kuroma.dev";
      EMAIL_FROM = "contact@kuroma.dev";
      EMAIL_FROM_NAME = "LibreChat";

      # Web search: metatron's searxng over tailscale 
      SEARXNG_INSTANCE_URL = "http://metatron:8888";
    };

    settings = {
      version = "1.2.1";
      cache = true;

      # Allow extra MCP (i.e. GraphIV)
      mcpSettings.allowedDomains = lib.mkIf graphiv.enable [
        "http://127.0.0.1:${toString graphiv.port}"
      ];

      webSearch = {
        searchProvider = "searxng";
        rerankerType = "none";
        # self-hosted firecrawl on uriel; key unused but required by the schema
        scraperType = "firecrawl";
        firecrawlApiUrl = "http://uriel:3002";
        firecrawlApiKey = "sk-ibidi-toilet";
      };

      endpoints.custom = [
      {
          name = "llama-router";
          apiKey = "sk-ibidi-toilet"; # haha imagine needing key
          baseURL = "http://localhost:${toString llama.port}/v1";
          models = {
            default = [ "Gemma-4-26B" ];
            fetch = true;
          };
          titleConvo = true;
          titleModel = "Gemma-4-26B";
          modelDisplayLabel = "llama-router";
        }
      ];

      mcpServers = lib.optionalAttrs graphiv.enable {
        graphiv = {
          type = "streamable-http";
          url = "http://127.0.0.1:${toString graphiv.port}/mcp";
          timeout = 7200000; # ms, deep_research holds the tool call up to 2 h
          initTimeout = 30000;
        };
      };
    };
  };

  services.meilisearch.masterKeyFile = config.sops.secrets."librechat/meili-master-key".path;
  services.meilisearch.settings = lib.mkIf (cfg.dataDir != null) {
    db_path = "${dirOf cfg.dataDir}/meilisearch";
    dump_dir = "${dirOf cfg.dataDir}/meilisearch/dumps";
    snapshot_dir = "${dirOf cfg.dataDir}/meilisearch/snapshots";
  };
  # pin static user to be able to read its own file
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
  # Keep mongo state next to librechat's when the host moves it off /var
  services.mongodb.dbpath = lib.mkIf (cfg.dataDir != null) "${dirOf cfg.dataDir}/mongodb";
  # The host.services glue orders only cfg.unit (librechat) on the storage mount
  systemd.services.mongodb = lib.mkIf (cfg.storage == "vault") {
    after = [ "Vault.mount" ];
    requires = [ "Vault.mount" ];
  };
}
