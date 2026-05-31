{ config, lib, pkgs, ... }:

# Multi-instance filebrowser template.
#
# Declare instances in the host:
#   host.filebrowsers.ct-dump = {
#     port = 8200;
#     root = "/tank/nas/ct/dump";
#     user = "ct";
#     group = "family";
#   };
#
# Each instance emits sops secrets, a hardened systemd unit, plus a
# host.services.<name> entry so caddy + storage glue come along for free.

let
  cfg = config.host.filebrowsers;

  mkConfig = name: i: pkgs.writeText "filebrowser-${name}.json" (builtins.toJSON {
    address = "127.0.0.1";
    port = i.port;
    root = i.root;
    database = "/var/lib/filebrowser-${name}/database.db";
  });

  mkService = name: i:
    let
      configFile = mkConfig name i;
      fb = lib.getExe pkgs.filebrowser;
    in {
      description = "FileBrowser — ${name}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = i.user;
        Group = i.group;
        StateDirectory = "filebrowser-${name}";
        ExecStartPre = pkgs.writeShellScript "filebrowser-${name}-init" ''
          set -euo pipefail
          DB="/var/lib/filebrowser-${name}/database.db"
          mkdir -p ${lib.escapeShellArg i.root}
          if [ ! -f "$DB" ]; then
            USERNAME="$(cat ${config.sops.secrets."filebrowser/${name}/username".path})"
            PASSWORD="$(cat ${config.sops.secrets."filebrowser/${name}/password".path})"
            ${fb} config init -d "$DB"
            ${fb} config set -d "$DB" -r ${lib.escapeShellArg i.root}
            ${fb} users add "$USERNAME" "$PASSWORD" --perm.admin -d "$DB"
            [ "$USERNAME" != "admin" ] && ${fb} users rm admin -d "$DB" || true
          fi
        '';
        ExecStart = "${fb} --config ${configFile}";
        Restart = "on-failure";
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        DevicePolicy = "closed";
      };
    };
in
{
  options.host.filebrowsers = lib.mkOption {
    default = {};
    description = "Filebrowser instances. Each entry gets a hardened systemd unit + caddy vhosts.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption { type = lib.types.port; };
        root = lib.mkOption { type = lib.types.str; };
        user = lib.mkOption { type = lib.types.str; };
        group = lib.mkOption { type = lib.types.str; };
        publicHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Defaults to <name>.kuroma.dev if null.";
        };
      };
    });
  };

  config = lib.mkIf (cfg != {}) {
    sops.secrets = lib.concatMapAttrs (name: i: {
      "filebrowser/${name}/username" = { owner = i.user; };
      "filebrowser/${name}/password" = { owner = i.user; };
    }) cfg;

    systemd.services = lib.mapAttrs' (name: i:
      lib.nameValuePair "filebrowser-${name}" (mkService name i)
    ) cfg;

    host.services = lib.mapAttrs (name: i: {
      enable = true;
      port = i.port;
      publicHost = if i.publicHost != null then i.publicHost else "${name}.kuroma.dev";
      dataDir = i.root;
      storage = "zfs";
      unit = "filebrowser-${name}";
    }) cfg;
  };
}
