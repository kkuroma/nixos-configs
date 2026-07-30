{ ... }:
{
  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    theme = "system";
    model = "llama-router/Gemma-4-26B-Code";
    provider = {
      llama-router-1 = {
        npm = "@ai-sdk/openai-compatible";
        name = "zaphkiel";
        options.baseURL = "https://llama.zaphkiel/v1";
        models = {
          "Gemma-4-26B-Code" = {
            name = "Gemma-4-26B-Code";
            limit = {
              context = 131072;
              output = 32768;
            };
          };
          "Gemma-4-12B-Code" = {
            name = "Gemma-4-12B-Code";
            limit = {
              context = 262144;
              output = 65536;
            };
          };
          "Qwen3.6-35B-A3B-Code" = {
            name = "Qwen3.6-35B-A3B-Code";
            limit = {
              context = 131072;
              output = 32768;
            };
          };
          "Qwen3.6-35B-A3B-Code-Uncen" = {
            name = "Qwen3.6-35B-A3B-Code-Uncen";
            limit = {
              context = 131072;
              output = 32768;
            };
          };
        };
      };
       llama-router-2 = {
        npm = "@ai-sdk/openai-compatible";
        name = "asgard";
        options.baseURL = "http://10.10.30.29:11434/v1";
        models = {
          "wordslop-qwen-3-6-27b" = {
            name = "wordslop-qwen-3-6-27b";
            limit = {
              context = 262144;
              output = 65536;
            };
          };
        };
      };
    };
    mcp = {
      searxng = {
        type = "local";
        command = [
          "npx"
          "-y"
          "mcp-searxng"
        ];
        environment.SEARXNG_URL = "https://searx.kuroma.dev";
        enabled = true;
      };
      graphiv = {
        type = "remote";
        url = "https://graphiv.zaphkiel/mcp";
        enabled = true;
      };
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "free-api-key-lmao";
        };
        enabled = true;
      };
    };
  };
}
