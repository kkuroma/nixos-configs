{ config, lib, ... }:

# Shared declarative shape for the small services in services/*.nix.
#
# Each service declares one entry under `host.services.<name>` describing
# its port, where its data lives, what storage it depends on, and whether it
# is exposed publicly. The generator below emits the Caddy vhosts and the
# systemd ordering edges, so the per-service file only needs the actual
# upstream config (services.jellyfin = { ... } etc.).
#
# `dataDir` is informational — the service file passes it into the upstream
# module itself (services.jellyfin.dataDir = cfg.dataDir). That way the host
# picks one path (/tank/... vs /Vault/...) and the service inherits it.

let
  cfg = config.host.services;
  hostName = config.networking.hostName;

  storageDeps = {
    zfs   = [ "zfs-datasets.service" ];
    vault = [ "Vault.mount" ];
    none  = [];
  };

  enabledWithStorage = lib.filterAttrs
    (_: s: s.enable && s.storage != "none")
    cfg;

  enabledWithCaddy = lib.filterAttrs (_: s: s.enable && s.port != null) cfg;

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
      };
    }));
  };

  config = {
    services.caddy.virtualHosts =
      (lib.mapAttrs' mkInternalVhost
        (lib.filterAttrs (_: s: s.internal) enabledWithCaddy))
      //
      (lib.mapAttrs' mkPublicVhost
        (lib.filterAttrs (_: s: s.publicHost != null && s.publicAuto) enabledWithCaddy));

    systemd.services = lib.mapAttrs' mkSystemdDeps enabledWithStorage;
  };
}
