{ lib, config, ... }:

let
  root = "/Vault/llm-models";
  mdl = name: file: "${root}/models/${name}/${file}";
  emb = name: file: "${root}/embeddings/${name}/${file}";
in
lib.mkIf (config.host.services.llama or { enable = false; }).enable {
  services.llama-router = {
    enable = true;
    host = "0.0.0.0";
    port = config.host.services.llama.port;
    user = "llama";
    group = "llama";
    modelDirs = [ "${root}/models" ];

    presetGlobals = {
      jinja = true;
      fa = true;
      ngl = 99;
      cram = 4096;
      models-max = 1;
      ctk = "q4_0";
      ctv = "q4_0";
    };

    models = {

      "GPT-OSS-20B" = {
        num_instance = 1;
        model = mdl "GPT-OSS-20B" "model_f16.gguf";
        c = 131072;
        b = 16384;
        ub = 1024;
        parallel = 1;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };

      "GPT-OSS-20B-Batched" = {
        num_instance = 1;
        model = mdl "GPT-OSS-20B" "model_f16.gguf";
        c = 131072;
        b = 16384;
        ub = 1024;
        parallel = 4;
      };

      "GLM-4.7-Flash" = {
        num_instance = 1;
        model = mdl "GLM-4.7-Flash" "model_iq4_xs.gguf";
        c = 131072;
        b = 16384;
        ub = 512;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };

      "GLM-4.7-Flash-Batched" = {
        num_instance = 1;
        model = mdl "GLM-4.7-Flash" "model_iq4_xs.gguf";
        c = 131072;
        b = 16384;
        ub = 512;
        parallel = 4;
      };

      "Gemma-4-26B" = {
        num_instance = 1;
        model = mdl "Gemma-4-26B-A4B" "model_mxfp4.gguf";
        model-draft = mdl "Gemma-4-26B-A4B" "mtp.gguf";
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

      "Gemma-4-26B-Batched" = {
        num_instance = 1;
        model = mdl "Gemma-4-26B-A4B" "model_mxfp4.gguf";
        model-draft = mdl "Gemma-4-26B-A4B" "mtp.gguf";
        spec-type = "draft-mtp";
        spec-draft-n-max = 4;
        c = 131072;
        b = 16384;
        ub = 512;
        parallel = 4;
      };

      "Gemma-4-26B-Vision" = {
        num_instance = 1;
        model = mdl "Gemma-4-26B-A4B" "model_mxfp4.gguf";
        mmproj = mdl "Gemma-4-26B-A4B" "mmproj.gguf";
        model-draft = mdl "Gemma-4-26B-A4B" "mtp.gguf";
        spec-type = "draft-mtp";
        spec-draft-n-max = 4;
        c = 65536;
        b = 8192;
        ub = 512;
        parallel = 1;
      };

      "Gemma-4-12B" = {
        num_instance = 1;
        model = mdl "Gemma-4-12B" "model_q8_0.gguf";
        model-draft = mdl "Gemma-4-12B" "mtp.gguf";
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

      "Gemma-4-12B-Batched" = {
        num_instance = 1;
        model = mdl "Gemma-4-12B" "model_q8_0.gguf";
        model-draft = mdl "Gemma-4-12B" "mtp.gguf";
        spec-type = "draft-mtp";
        spec-draft-n-max = 4;
        c = 262144;
        b = 8192;
        ub = 512;
        parallel = 4;
      };

      "Gemma-4-12B-Vision" = {
        num_instance = 1;
        model = mdl "Gemma-4-12B" "model_q8_0.gguf";
        mmproj = mdl "Gemma-4-12B" "mmproj.gguf";
        model-draft = mdl "Gemma-4-12B" "mtp.gguf";
        spec-type = "draft-mtp";
        spec-draft-n-max = 4;
        c = 262144;
        b = 8192;
        ub = 512;
        parallel = 1;
      };

      "Qwen3.6-35B-A3B" = {
        num_instance = 1;
        model = mdl "Qwen-3.6-35B-A3B" "model_iq4_xs.gguf";
        c = 131072;
        b = 16384;
        ub = 512;
        parallel = 1;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };

      "Qwen3.6-35B-Uncensored" = {
        num_instance = 1;
        model = mdl "Qwen-3.6-35B-A3B-Uncensored" "model_iq4_xs.gguf";
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
        model = mdl "Ornith-1.0-35B-A3B" "model_q4_k_m.gguf";
        c = 16384;
        b = 8192;
        ub = 512;
        parallel = 1;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };

      "ThinkingCap-Qwen3.6-27B" = {
        num_instance = 1;
        model = mdl "ThinkingCap-Qwen-3.6-27B" "model_q4_k_m.gguf";
        spec-type = "draft-mtp";
        c = 131072;
        b = 16384;
        ub = 512;
        parallel = 1;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };

      "Wordslop-Qwen3.6-27B" = {
        num_instance = 1;
        model = mdl "Wordslop-Qwen-3.6-27B" "model_iq2_m.gguf";
        spec-type = "draft-mtp";
        c = 262144;
        b = 16384;
        ub = 512;
        parallel = 1;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };
    };
  };

  systemd.services.llama-embed = {
    description = "llama.cpp embedding server (nomic-embed-text-v2-moe)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "Vault.mount" ];
    requires = [ "Vault.mount" ];
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe' config.services.llama-router.llamaCpp "llama-server")
        "--embedding"
        "-m ${emb "Nomic-Embed-Text-v2-MoE" "model_f16.gguf"}"
        "--alias nomic-embed-text-v2-moe"
        "--host 0.0.0.0"
        "--port 11435"
        "-ngl 99"
        "-c 8192"
        "-b 8192"
        "-ub 2048"
        "--parallel 4"
        "--pooling mean"
      ];
      User = "llama";
      Group = "llama";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
