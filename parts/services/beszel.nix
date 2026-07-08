{ config, lib, ... }:
let
  cfg = config.host.services.beszel or null;
in
{
  # The hub's SSH public key, shown in its "Add System" dialog after first-run setup. Public value, safe in the repo. null = local agent stays off
  options.host.beszelAgentKey = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Beszel hub public key; enables the loopback agent when set.";
  };

  config = lib.mkIf (cfg != null && cfg.enable) {
    sops.secrets."beszel/email" = { };
    sops.secrets."beszel/password" = { };

    # Seeds the first admin account on a fresh hub; ignored once it exists
    sops.templates."beszel-hub-env".content = ''
      USER_EMAIL=${config.sops.placeholder."beszel/email"}
      USER_PASSWORD=${config.sops.placeholder."beszel/password"}
    '';

    services.beszel = {
      hub = {
        enable = true;
        port = cfg.port;
        environmentFile = config.sops.templates."beszel-hub-env".path;
      };

      # Each hub monitors its own machine: pair by setting host.beszelAgentKey, then Add System -> localhost:45876 in the hub UI
      agent = lib.mkIf (config.host.beszelAgentKey != null) {
        enable = true;
        environment = {
          LISTEN = "127.0.0.1:45876";
          KEY = config.host.beszelAgentKey;
        };
      };
    };
  };
}
