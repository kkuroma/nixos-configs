{ pkgs, config, lib, ... }:

# Multi-instance cloudflared tunnels: host.cloudflared.<name> = { tokenSecret = "..."; };
# hostnames defaults to every enabled host.services publicHost — override only for names served elsewhere.

let
  cfg = config.host.cloudflared;
  yaml = pkgs.formats.yaml { };

  publicHosts = lib.mapAttrsToList (_: s: s.publicHost)
    (lib.filterAttrs (_: s: s.enable && s.publicHost != null) config.host.services);

  mkConfig = name: i: yaml.generate "cloudflared-${name}.yaml" {
    ingress = map (h: { hostname = h; inherit (i) service; }) i.hostnames
      ++ [ { service = "http_status:404"; } ];
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
          default = publicHosts;
          defaultText = "every enabled host.services publicHost on this host";
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
      lib.nameValuePair "cloudflared-${name}" {
        description = "Cloudflare Tunnel — ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "sops-install-secrets.service" ];
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe pkgs.cloudflared)
            "tunnel --no-autoupdate"
            "--config ${mkConfig name i}"
            "run --token-file ${config.sops.secrets.${i.tokenSecret}.path}"
          ];
          Restart = "always";
          RestartSec = "5s";
          DynamicUser = true;
        };
      }
    ) cfg;
  };
}
