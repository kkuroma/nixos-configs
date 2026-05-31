{ pkgs, config, lib, ... }:

# Multi-instance cloudflared tunnels.
#
# Declare in host:
#   host.cloudflared.main = {
#     hostnames = [ "vault.kuroma.dev" "git.kuroma.dev" ];
#     # tokenSecret defaults to "cloudflared/<name>/token";
#     # set explicitly if you want to reuse an existing sops key.
#   };

let
  cfg = config.host.cloudflared;

  mkConfigYaml = name: i: pkgs.writeText "cloudflared-${name}.yaml" ''
    ingress:
${lib.concatMapStrings (h: "      - hostname: ${h}\n        service: ${i.service}\n") i.hostnames}      - service: http_status:404
  '';

  mkService = name: i: {
    description = "Cloudflare Tunnel — ${name}";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "sops-install-secrets.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.writeShellScript "cloudflared-${name}-start" ''
        exec ${pkgs.cloudflared}/bin/cloudflared tunnel \
          --no-autoupdate \
          --config ${mkConfigYaml name i} \
          run --token "$(cat ${config.sops.secrets.${i.tokenSecret}.path})"
      ''}";
      Restart = "always";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };
in
{
  options.host.cloudflared = lib.mkOption {
    default = {};
    description = "Cloudflare tunnel instances.";
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        hostnames = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Public hostnames this tunnel ingresses.";
        };
        service = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:80";
          description = "Where the tunnel forwards — usually caddy on :80.";
        };
        tokenSecret = lib.mkOption {
          type = lib.types.str;
          default = "cloudflared/${name}/token";
          description = "sops secret path holding the tunnel token.";
        };
      };
    }));
  };

  config = lib.mkIf (cfg != {}) {
    sops.secrets = lib.mapAttrs' (_: i:
      lib.nameValuePair i.tokenSecret { mode = "0444"; }
    ) cfg;

    systemd.services = lib.mapAttrs' (name: i:
      lib.nameValuePair "cloudflared-${name}" (mkService name i)
    ) cfg;
  };
}
