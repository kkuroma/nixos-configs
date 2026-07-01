{ pkgs, lib, config, ... }:

let
  llamaSrc = ./llama-router/src;
  llamaEnv = pkgs.python3.withPackages (ps: with ps; [
    fastapi
    uvicorn
    httpx
    aiosqlite
    pynvml
  ]);

  # Global llama.cpp settings applied to every preset (the "[*]" wildcard section).
  presetGlobals = {
    jinja = true;
    fa = true;
    ngl = 99;
    cram = 4096;
    models-max = 1;
    ctk = "q4_0";
    ctv = "q4_0";
  };

  # This is where all model configs are declared. Populates both the llama.cpp presets.ini and my router's config.json
  models = {
    "GPT-OSS-20B" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gpt-oss-20b-F16.gguf";
      c = 131072;
      b = 16384;
      ub = 1024;
      parallel = 4;
    };

    "GPT-OSS-20B-Code" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gpt-oss-20b-F16.gguf";
      c = 131072;
      b = 16384;
      ub = 1024;
      parallel = 1;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };

    "GLM-4.7-Flash" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/GLM-4.7-Flash-IQ4_XS.gguf";
      c = 65536;
      b = 16384;
      ub = 512;
      parallel = 4;
    };

    "GLM-4.7-Flash-Code" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/GLM-4.7-Flash-IQ4_XS.gguf";
      c = 131072;
      b = 16384;
      ub = 512;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };

    "Gemma-4-26B" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
      c = 65536;
      b = 16384;
      ub = 512;
      parallel = 4;
    };

    "Gemma-4-26B-Code" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
      model-draft = "/Vault/llm-models/models/gemma-4-26B-A4B-it-mtp.gguf";
      spec-type = "draft-mtp";
      spec-draft-n-max = 4;
      c = 131072;
      b = 16384;
      ub = 512;
      parallel = 1;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };

    "Gemma-4-26B-Vision" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
      mmproj = "/Vault/llm-models/models/gemma-4-26B-A4B-it-mmproj-BF16.gguf";
      model-draft = "/Vault/llm-models/models/gemma-4-26B-A4B-it-mtp.gguf";
      spec-type = "draft-mtp";
      spec-draft-n-max = 4;
      c = 32768;
      b = 8192;
      ub = 512;
      parallel = 1;
    };

    "Gemma-4-12B" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gemma-4-12b-it-Q8_0.gguf";
      c = 262144;
      b = 8192;
      ub = 512;
      parallel = 4;
    };

    "Gemma-4-12B-Code" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gemma-4-12b-it-Q8_0.gguf";
      model-draft = "/Vault/llm-models/models/gemma-4-12b-it-mtp.gguf";
      spec-type = "draft-mtp";
      spec-draft-n-max = 4;
      c = 262144;
      b = 8192;
      ub = 512;
      parallel = 1;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };

    "Gemma-4-12B-Vision" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/gemma-4-12b-it-Q8_0.gguf";
      mmproj = "/Vault/llm-models/models/gemma-4-12b-it-mmproj-BF16.gguf";
      model-draft = "/Vault/llm-models/models/gemma-4-12b-it-mtp.gguf";
      spec-type = "draft-mtp";
      spec-draft-n-max = 4;
      c = 262144;
      b = 8192;
      ub = 512;
      parallel = 1;
    };

    "Qwen3-4B-Instruct" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/Qwen3-4B-Instruct-2507-Q8_0.gguf";
      c = 65536;
      b = 4096;
      ub = 512;
      parallel = 4;
    };

    "Qwen3-4B-Instruct-Swarm" = {
      num_instance = 2;
      model = "/Vault/llm-models/models/Qwen3-4B-Instruct-2507-Q8_0.gguf";
      c = 32768;
      b = 4096;
      ub = 512;
      parallel = 8;
    };

    "Qwen3.5-9B" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/Qwen3.5-9B-Q4_0.gguf";
      c = 262144;
      b = 4096;
      ub = 512;
      parallel = 1;
      chat-template-kwargs = ''{"enable_thinking": true}'';
    };

    "Qwen3-30B-Coder" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/Qwen3-Coder-30B-A3B-Instruct-Q4_0.gguf";
      c = 16384;
      b = 16384;
      ub = 512;
      parallel = 2;
      temp = "0.7";
      top-p = "1.0";
      min-p = "0.01";
    };

    "Qwen3.6-35B-A3B-Code" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf";
      c = 131072;
      b = 16384;
      ub = 512;
      parallel = 1;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };

    "Qwen3.6-35B-A3B-Code-Uncen" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/Qwen3.6-35B-A3B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf";
      c = 131072;
      b = 16384;
      ub = 512;
      parallel = 1;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };

    "Ornith1.0-35B" = {
      num_instance = 1;
      model = "/Vault/llm-models/models/ornith-1.0-35b-Q4_K_M.gguf";
      c = 16384;
      b = 8192;
      ub = 512;
      parallel = 1;
      temp = "1.0";
      top-p = "0.95";
      min-p = "0.01";
    };
  };

  # Router JSON: pick num_instance per model out of the shared `models` attrset.
  routerConfig = pkgs.writeText "llama-router-config.json" (builtins.toJSON {
    LLM = lib.mapAttrs (_: m: { inherit (m) num_instance; }) models;
    ROUTER = {
      HEALTH_CHECK_INTERVAL = 1.0;
      HEALTH_CHECK_TIMEOUT = 30.0;
      UNLOAD_POLL_INTERVAL = 0.5;
      UNLOAD_POLL_TIMEOUT = 60.0;
      LOAD_POLL_INTERVAL = 1.0;
      LOAD_POLL_TIMEOUT = 120.0;
      START_RETRIES = 3;
      GRACEFUL_KILL_TIMEOUT = 5.0;
    };
    "API-port" = config.host.services.llama.port;
    "LLM-base-port" = 30000;
    "llama-server-executable" = "${pkgs.llama-cpp}/bin/llama-server";
  });

  # Preset INI: drop num_instance (router-only) from each model, prepend the "[*]" globals
  presetsFormat = pkgs.formats.ini {
    mkKeyValue = lib.generators.mkKeyValueDefault {} " = ";
  };
  presetsIni = presetsFormat.generate "llama-presets.ini" (
    { "*" = presetGlobals; }
    // lib.mapAttrs (_: m: removeAttrs m [ "num_instance" ]) models
  );

  embPort = toString config.host.services.llama-emb.port;
in
lib.mkIf (config.host.services.llama or { enable = false; }).enable {
  users.users.llama = {
    isSystemUser = true;
    group = "llama";
    extraGroups = [ "video" "render" ];
  };
  users.groups.llama = {};

  systemd.tmpfiles.rules = [
    "d /Vault/llm-models 0755 llama llama -"
    "d /Vault/llm-models/models 0755 llama llama -"
    "d /Vault/llm-models/embeddings 0755 llama llama -"
  ];

  systemd.services.llama-router = {
    description = "LLaMA.cpp Router";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      ROUTER_CONFIG_PATH = "${routerConfig}";
      LLAMA_PRESETS_PATH = "${presetsIni}";
      HISTORY_DB_PATH = "/var/lib/llama-router/monitor/history.db";
    };
    serviceConfig = {
      ExecStart = "${llamaEnv}/bin/python3 ${llamaSrc}/main.py";
      WorkingDirectory = "/var/lib/llama-router";
      StateDirectory = "llama-router";
      User = "llama";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.llama-embedding = {
    description = "LLaMA.cpp Embedding Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--host 127.0.0.1 --port ${embPort}"
        "--model /Vault/llm-models/embeddings/nomic-embed-text-v2-moe.Q4_0.gguf"
        "--embedding --pooling cls"
        "--ctx-size 2048 --parallel 4 --n-gpu-layers -1"
      ];
      User = "llama";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
