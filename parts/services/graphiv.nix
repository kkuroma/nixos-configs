{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.host.services.graphiv or null;
  llama = config.host.services.llama or { port = 11434; };
  hostName = config.networking.hostName;
  root = cfg.dataDir or "/Vault/graphiv";
  corpus = "/mnt/Vault-Storage/research/arxiv";
  apiPort = cfg.port or 6767;
  frontendPort = apiPort + 202;
  managerPort = apiPort + 101;
  recipes = "${pkgs.graphiv}/share/graphiv/retrieval_recipes";
in
lib.mkIf (cfg != null && cfg.enable) {
  services.graphiv = {
    enable = true;
    package = pkgs.graphiv;
    user = "graphiv";
    group = "graphiv";
    stateDir = root;
    dataDir = "${root}/data";
    venvDir = "${root}/venv";
    endpointUnits = [
      "llama-router.service"
      "llama-embed.service"
    ];

    # the cluster
    postgres = {
      enable = true;
      package = pkgs.postgresql_17.withPackages (p: [ p.pgvector ]);
      dataDir = "${root}/data/pg";
      socketDir = "/run/graphiv";
      port = 5433;
      database = "arxivkg";
      settings = {
        listen_addresses = "";
        max_connections = 100;
        shared_buffers = "4GB";
        work_mem = "256MB";
        maintenance_work_mem = "2GB";
        max_parallel_maintenance_workers = 4;
        dynamic_shared_memory_type = "posix";
        default_toast_compression = "lz4";
        checkpoint_timeout = "30min";
        max_wal_size = "64GB";
        min_wal_size = "80MB";
        DateStyle = "ISO, MDY";
        TimeZone = "Asia/Tokyo";
        log_timezone = "Asia/Tokyo";
        lc_messages = "C";
        lc_monetary = "C";
        lc_numeric = "C";
        lc_time = "C";
        default_text_search_config = "pg_catalog.english";
      };
    };

    # the three units
    api = {
      enable = true;
      readOnly = false;
      restartOnExport = true;
    };

    frontend.enable = true;

    manager = {
      enable = true;
      databaseUser = "kuroma";
      path = [
        pkgs.aria2
        pkgs.curl
        config.hardware.nvidia.package.bin
      ];
    };

    # config.toml
    settings = {
      database = {
        PG_DEST = "host=/run/graphiv port=5433 dbname=arxivkg";
      };

      source = {
        SOURCE_URL = "https://www.kaggle.com/api/v1/datasets/download/Cornell-University/arxiv";
        SOURCE_PATH = "${root}/data/arxiv.json";
        PDF_BASE_URL = "https://storage.googleapis.com/arxiv-dataset/arxiv/arxiv/pdf";
        PDF_LEGACY_BASE_URL = "https://storage.googleapis.com/arxiv-dataset/arxiv";
        HTML_BASE_URL = "https://arxiv.org/html";
        HTML_FALLBACK_URL = "https://ar5iv.labs.arxiv.org/html";
      };

      download = {
        PDF_BATCH = 500;
        PDF_N_PARALLEL = 8;
        HTML_RATE = 8.0;
        HTML_BATCH = 200;
        HTML_N_PARALLEL = 16;
      };

      dataset = {
        PDF_PATH = "${corpus}/pdfs";
        HTML_PATH = "${corpus}/html";
        GRAPH_PATH = "${root}/data/citation_graph_export.npy";
      };

      serve = {
        HOST = "127.0.0.1";
        API_PORT = apiPort;
        FRONTEND_PORT = frontendPort;
        ALLOWED_HOSTS = [ "graphiv.${hostName}" ] ++ lib.optional (cfg.publicHost != null) cfg.publicHost;
        RECIPE_PATH = recipes;
        RUNS_PATH = "${root}/runs";
        CACHE_PATH = "${root}/cache";
        FETCH = true;
      };

      manager = {
        PORT = managerPort;
        STATE_PATH = "${root}/manager";
      };

      endpoints = {
        EMBED_API = "http://127.0.0.1:11435";
        EMBED_NAME = "nomic-embed-text-v2-moe";
        EMBED_PARALLEL = 1;
        EMBED_BATCH = 256;
        EMBED_MAX_SEQ = 512;
        EMBED_PREFIX = "search_document: ";
        LLM_API = "http://127.0.0.1:${toString llama.port}/v1";
        LLM_NAME = "Gemma-4-26B-Batched";
      };

      survey = {
        MODEL_PATH = "${root}/data/survey_detection";
        BATCH = 64;
        CHUNK = 50000;
      };

      umap = {
        UMAP_MODEL_PATH = "${root}/data/umap_50.joblib";
        UMAP_SAMPLE = 400000;
        UMAP_SEED = 69420;
        UMAP_DIM = 50;
        UMAP_BATCH = 50000;
        UMAP_WORKERS = 4;
      };

      topics = {
        TREE_METHODS = [
          "kmeans"
          "kmeans"
          "kmeans"
        ];
        TREE_K = 16;
        TREE_MIN_CLUSTER_SIZE = 60;
        TREE_N_PARALLEL = 8;
        TREE_BATCH = 50000;
        TREE_SEED = 69420;
        N_TOPIC_LABEL = 10;
        TOPIC_BATCH = 8;
      };

      citation_labeler = {
        LABELER_PATH = "${root}/data/citation_labeler";
        LABELER_MODEL = "distilbert/distilbert-base-uncased";
        LABELER_BATCH = 48;
        LABELER_MAX_SEQ = 256;
        LABELER_APE_MODEL = "Gemma-4-26B-Batched";
        LABELER_APE_GENERATIONS = 6;
        LABELER_APE_PARALLEL = 4;
        LABELER_TEACHER_SAMPLE = 10000;
        LABELER_SEED = 0;
        LABELER_SPLITS = [
          0.8
          0.1
          0.1
        ];
        LABELER_EPOCHS = 12;
        LABELER_TRAIN_BATCH = 64;
        LABELER_LR = 2.0e-5;
      };

      surveymatch = {
        SURVEY_THRESHOLD = 0.5;
        MUTUAL_COSINE_THRESHOLD = 0.65;
        SURVEYMATCH_LEVEL = 2;
      };

      retriever_eval = {
        RECIPE_PATH = recipes;
        OUTPUT_PATH = "${root}/experiments/retrieve";
        RETURN_LIMIT = 1000;
        BUDGETS = [
          100
          200
          500
          1000
        ];
        SEED = 0;
        SAMPLE_RATE = 1.0;
        MAX_SAMPLES = 300;
        SURVEY_THRESHOLD = 0.95;
        MIN_REFERENCES = 25;
        GAP_DAYS = 190;
        FRONTIER_COSINE = 0.8;
        FRONTIER_MIN_KEY = 10;
        FRONTIER_WINDOW_DAYS = 730;
        CONSENSUS_COSINE = 0.75;
        CONSENSUS_MIN_KEY = 5;
        PRECISION_LEVEL = 2;
        recipes = {
          SurveyMatch = [
            "survey.toml"
            "anc_only.toml"
            "survey_no_forward.toml"
            "all_terms.toml"
            "no_expansion.toml"
            "cosine_only.toml"
          ];
          FrontierMatch = [
            "frontier.toml"
            "survey.toml"
            "frontier_no_forward.toml"
            "all_terms.toml"
            "cosine_only.toml"
          ];
          ConsensusMatch = [
            "consensus.toml"
            "consensus_no_forward.toml"
            "survey.toml"
            "all_terms.toml"
            "cosine_only.toml"
          ];
          PrecisionMatch = [
            "survey.toml"
            "frontier.toml"
            "cosine_only.toml"
          ];
        };
      };
    };
  };

  # the user and group
  users.users.graphiv = {
    isSystemUser = true;
    group = "graphiv";
    home = root;
    description = "GraphIV";
  };

  users.groups.graphiv = { };

  users.users.kuroma.extraGroups = [ "graphiv" ];

  # the reverse proxy: tools and manager on the tailnet, the dashboard alone on the tunnel
  services.caddy.virtualHosts = {
    "graphiv.${hostName}".extraConfig = ''
      tls internal
      reverse_proxy localhost:${toString apiPort}
    '';
    "graphiv-manager.${hostName}".extraConfig = ''
      tls internal
      reverse_proxy localhost:${toString managerPort}
    '';
  }
  // lib.optionalAttrs (cfg.publicHost != null) {
    "http://${cfg.publicHost}".extraConfig = ''
      reverse_proxy localhost:${toString frontendPort}
    '';
  };
}
