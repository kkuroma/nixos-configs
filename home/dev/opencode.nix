{ inputs, ... }:
{
  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    # The Kuroma manual: brevity rules into the system prompt, comment linter onto every edit
    plugin = [ "${inputs.coding-style}/opencode/plugin.js" ];
    autoupdate = false;
    theme = "system";
    model = "llama-router-1/Gemma-4-26B";
    provider = {
      llama-router-1 = {
        npm = "@ai-sdk/openai-compatible";
        name = "zaphkiel";
        options.baseURL = "https://llama.zaphkiel/v1";
        models = {
          "Wordslop-Qwen3.6-27B" = {
            name = "Wordslop-Qwen3.6-27B";
            limit = {
              context = 262144;
              output = 32768;
            };
          };
          "Gemma-4-26B" = {
            name = "Gemma-4-26B";
            limit = {
              context = 131072;
              output = 32768;
            };
          };
          "Gemma-4-12B" = {
            name = "Gemma-4-12B";
            limit = {
              context = 262144;
              output = 65536;
            };
          };
          "Qwen3.6-35B-A3B" = {
            name = "Qwen3.6-35B-A3B";
            limit = {
              context = 131072;
              output = 32768;
            };
          };
          "Qwen3.6-35B-A3B-Uncensored" = {
            name = "Qwen3.6-35B-A3B-Uncensored";
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
