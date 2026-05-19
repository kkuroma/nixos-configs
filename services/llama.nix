{ pkgs, lib, config, ... }:

let
  llamaSrc = ../services/llama-router/src;
  llamaEnv = pkgs.python3.withPackages (ps: with ps; [
    fastapi
    uvicorn
    httpx
    aiosqlite
    pynvml
  ]);

  routerConfig = pkgs.writeText "llama-router-config.json" (builtins.toJSON {
    LLM = {
      "GPT-OSS-20B" = { num_instance = 1; };
      "GPT-OSS-20B-Code" = { num_instance = 1; };
      "GLM-4.7-Flash" = { num_instance = 1; };
      "GLM-4.7-Flash-Code" = { num_instance = 1; };
      "Qwen3-4B-Instruct" = { num_instance = 1; };
      "Qwen3-4B-Instruct-Swarm" = { num_instance = 2; };
      "Qwen3-30B-Coder" = { num_instance = 1; };
      "Qwen3.5-9B" = { num_instance = 1; };
      "Gemma-4-26B" = { num_instance = 1; };
      "Gemma-4-26B-Code" = { num_instance = 1; };
    };
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
    "API-port" = 11434;
    "LLM-base-port" = 30000;
    "llama-server-executable" = "${pkgs.llama-cpp}/bin/llama-server";
  });
in
{
  services.caddy.virtualHosts = {
    "llama.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:11434";
    "llama-emb.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:11435";
  };

  users.users.llama = {
    isSystemUser = true;
    group = "llama";
    extraGroups = [ "video" "render" ];
  };
  users.groups.llama = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/llm-models 0755 llama llama -"
    "d /var/lib/llm-models/models 0755 llama llama -"
    "d /var/lib/llm-models/embeddings 0755 llama llama -"
  ];

  systemd.services.llama-router = {
    description = "LLaMA.cpp Router";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      ROUTER_CONFIG_PATH = "${routerConfig}";
      LLAMA_PRESETS_PATH = "/etc/llamacpp/presets.ini";
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

  environment.etc."llamacpp/presets.ini".source = ../services/llama-router/presets.ini;

  systemd.services.llama-embedding = {
    description = "LLaMA.cpp Embedding Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--host 0.0.0.0 --port 11435"
        "--model /var/lib/llm-models/embeddings/nomic-embed-text-v2-moe.Q4_0.gguf"
        "--embedding --pooling cls"
        "--ctx-size 2048 --parallel 4 --n-gpu-layers -1"
      ];
      User = "llama";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
