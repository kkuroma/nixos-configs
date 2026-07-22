{ lib, config, ... }:

# Thin wiring over the llama-router flake module (git.kuroma.dev/kkuroma/llama-router).
# Caddy vhost + firewall come from host.services.llama as before.
lib.mkIf (config.host.services.llama or { enable = false; }).enable {
  services.llama-router = {
    enable = true;
    host = "0.0.0.0"; # firewall scopes 11434 to tailscale0
    port = config.host.services.llama.port;
    user = "llama";
    group = "llama";
    modelDirs = [ "/Vault/llm-models" ];

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

    # This is where all model configs are declared. Populates both the llama.cpp presets.ini and the router's config.json
    models = {
      "GPT-OSS-20B" = {
        num_instance = 1;
        model = "/Vault/llm-models/gpt-oss-20b-F16.gguf";
        c = 131072;
        b = 16384;
        ub = 1024;
        parallel = 4;
      };

      "GPT-OSS-20B-Code" = {
        num_instance = 1;
        model = "/Vault/llm-models/gpt-oss-20b-F16.gguf";
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
        model = "/Vault/llm-models/GLM-4.7-Flash-IQ4_XS.gguf";
        c = 65536;
        b = 16384;
        ub = 512;
        parallel = 4;
      };

      "GLM-4.7-Flash-Code" = {
        num_instance = 1;
        model = "/Vault/llm-models/GLM-4.7-Flash-IQ4_XS.gguf";
        c = 131072;
        b = 16384;
        ub = 512;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };

      "DiffusionGemma-4-26B" = {
        num_instance = 1;
        model = "/Vault/llm-models/diffusiongemma-26B-A4B-it-Q4_K_M.gguf";
        c = 131072;
        b = 16384;
        ub = 512;
        parallel = 4;
      };

      "Gemma-4-26B" = {
        num_instance = 1;
        model = "/Vault/llm-models/gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
        c = 131072;
        b = 16384;
        ub = 512;
        parallel = 4;
      };

      "Gemma-4-26B-Code" = {
        num_instance = 1;
        model = "/Vault/llm-models/gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
        model-draft = "/Vault/llm-models/gemma-4-26B-A4B-it-mtp.gguf";
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
        model = "/Vault/llm-models/gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
        mmproj = "/Vault/llm-models/gemma-4-26B-A4B-it-mmproj-BF16.gguf";
        model-draft = "/Vault/llm-models/gemma-4-26B-A4B-it-mtp.gguf";
        spec-type = "draft-mtp";
        spec-draft-n-max = 4;
        c = 65536;
        b = 8192;
        ub = 512;
        parallel = 1;
      };

      "Gemma-4-12B" = {
        num_instance = 1;
        model = "/Vault/llm-models/gemma-4-12b-it-Q8_0.gguf";
        c = 262144;
        b = 8192;
        ub = 512;
        parallel = 4;
      };

      "Gemma-4-12B-Code" = {
        num_instance = 1;
        model = "/Vault/llm-models/gemma-4-12b-it-Q8_0.gguf";
        model-draft = "/Vault/llm-models/gemma-4-12b-it-mtp.gguf";
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
        model = "/Vault/llm-models/gemma-4-12b-it-Q8_0.gguf";
        mmproj = "/Vault/llm-models/gemma-4-12b-it-mmproj-BF16.gguf";
        model-draft = "/Vault/llm-models/gemma-4-12b-it-mtp.gguf";
        spec-type = "draft-mtp";
        spec-draft-n-max = 4;
        c = 262144;
        b = 8192;
        ub = 512;
        parallel = 1;
      };

      "Qwen3-4B-Instruct" = {
        num_instance = 1;
        model = "/Vault/llm-models/Qwen3-4B-Instruct-2507-Q8_0.gguf";
        c = 65536;
        b = 4096;
        ub = 512;
        parallel = 4;
      };

      "Qwen3-4B-Instruct-Swarm" = {
        num_instance = 2;
        model = "/Vault/llm-models/Qwen3-4B-Instruct-2507-Q8_0.gguf";
        c = 32768;
        b = 4096;
        ub = 512;
        parallel = 8;
      };

      "Qwen3.5-9B" = {
        num_instance = 1;
        model = "/Vault/llm-models/Qwen3.5-9B-Q4_0.gguf";
        c = 262144;
        b = 4096;
        ub = 512;
        parallel = 1;
        chat-template-kwargs = ''{"enable_thinking": true}'';
      };

      "Qwen3-30B-Coder" = {
        num_instance = 1;
        model = "/Vault/llm-models/Qwen3-Coder-30B-A3B-Instruct-Q4_0.gguf";
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
        model = "/Vault/llm-models/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf";
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
        model = "/Vault/llm-models/Qwen3.6-35B-A3B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf";
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
        model = "/Vault/llm-models/ornith-1.0-35b-Q4_K_M.gguf";
        c = 16384;
        b = 8192;
        ub = 512;
        parallel = 1;
        temp = "1.0";
        top-p = "0.95";
        min-p = "0.01";
      };
    };
  };
}
