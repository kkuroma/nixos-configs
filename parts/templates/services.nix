{ config, lib, ... }:

# Schema + glue for host.services.<name>: emits caddy vhosts, systemd storage deps, and
# tailscale0 firewall ports. dataDir is informational — each service file passes cfg.dataDir upstream.

let
  cfg = config.host.services;
  hostName = config.networking.hostName;

  storageDeps = {
    zfs   = [ "zfs-datasets.service" ];
    vault = [ "Vault.mount" ];
    none  = [];
  };

  enabled = lib.filterAttrs (_: s: s.enable) cfg;

  enabledWithStorage = lib.filterAttrs (_: s: s.storage != "none") enabled;

  enabledWithCaddy = lib.filterAttrs (_: s: s.port != null) enabled;

  unknownServices = lib.subtractLists config.host.knownServices (lib.attrNames cfg);

  mkInternalVhost = name: s: {
    name = "${name}.${hostName}";
    value.extraConfig = ''
      tls internal
      reverse_proxy localhost:${toString s.port}
    '' + lib.optionalString (s.caddyExtra != "") ("\n" + s.caddyExtra);
  };

  mkPublicVhost = name: s: {
    name = "http://${s.publicHost}";
    value.extraConfig = "reverse_proxy localhost:${toString s.port}";
  };

  mkSystemdDeps = _: s: {
    name = s.unit;
    value = {
      after    = storageDeps.${s.storage};
      requires = storageDeps.${s.storage};
    };
  };
in
{
  # Valid host.services keys, registered from parts/services/*.nix filenames (+ filebrowser
  # instances); the assertion below turns a typoed key from a silent no-op into an eval error.
  options.host.knownServices = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    internal = true;
    description = "Valid host.services keys.";
  };

  options.host.services = lib.mkOption {
    default = {};
    description = "Declarative glue for caddy vhosts + systemd storage deps.";
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        enable = lib.mkEnableOption "system service ${name}";

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "Loopback port the service listens on. null = no Caddy vhost.";
        };

        publicHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "vault.kuroma.dev";
          description = "If set, also expose at http://<publicHost> for cloudflared.";
        };

        publicAuto = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            If true, auto-emit a plain reverse_proxy vhost for publicHost.
            Set false when the service writes its own (e.g. .well-known handlers).
          '';
        };

        internal = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Expose at https://<name>.<hostname> via tls internal.";
        };

        dataDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Where this service's state lives. Informational — the service's
            own file reads cfg.dataDir and passes it to the upstream module.
          '';
        };

        storage = lib.mkOption {
          type = lib.types.enum [ "zfs" "vault" "none" ];
          default = "none";
          description = "What dataDir lives on, drives systemd ordering.";
        };

        unit = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "systemd unit to attach storage deps to (defaults to <name>).";
        };

        caddyExtra = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Extra Caddy directives appended to the internal vhost.";
        };

        tailscalePorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = "TCP ports opened on tailscale0 for clients that bypass Caddy.";
        };
      };
    }));
  };

  config = {
    assertions = [{
      assertion = unknownServices == [];
      message = "host.services declares unknown service(s): ${toString unknownServices} — no matching parts/services/<name>.nix (typo?).";
    }];

    networking.firewall.interfaces.tailscale0.allowedTCPPorts =
      lib.concatMap (s: s.tailscalePorts) (lib.attrValues enabled);

    services.caddy.virtualHosts =
      (lib.mapAttrs' mkInternalVhost
        (lib.filterAttrs (_: s: s.internal) enabledWithCaddy))
      //
      (lib.mapAttrs' mkPublicVhost
        (lib.filterAttrs (_: s: s.publicHost != null && s.publicAuto) enabledWithCaddy));

    systemd.services = lib.mapAttrs' mkSystemdDeps enabledWithStorage;
  };
}
