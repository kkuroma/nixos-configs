{ config, lib, pkgs, ... }:

let
  instances = {
    ct-dump = {
      port = 8200;
      root = "/tank/nas/ct/dump";
      user = "ct";
      group = "family";
    };
  };

  mkConfig = name: cfg: pkgs.writeText "filebrowser-${name}.json" (builtins.toJSON {
    address = "127.0.0.1";
    port = cfg.port;
    root = cfg.root;
    database = "/var/lib/filebrowser-${name}/database.db";
  });

  mkService = name: cfg:
    let
      configFile = mkConfig name cfg;
      fb = lib.getExe pkgs.filebrowser;
    in {
      description = "FileBrowser — ${name}";
      after = [ "network.target" "zfs-datasets.service" ];
      requires = [ "zfs-datasets.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "filebrowser-${name}";
        ExecStartPre = pkgs.writeShellScript "filebrowser-${name}-init" ''
          set -euo pipefail
          DB="/var/lib/filebrowser-${name}/database.db"
          mkdir -p ${lib.escapeShellArg cfg.root}
          if [ ! -f "$DB" ]; then
            USERNAME="$(cat ${config.sops.secrets."filebrowser/${name}/username".path})"
            PASSWORD="$(cat ${config.sops.secrets."filebrowser/${name}/password".path})"
            ${fb} config init -d "$DB"
            ${fb} config set -d "$DB" -r ${lib.escapeShellArg cfg.root}
            ${fb} users add "$USERNAME" "$PASSWORD" --perm.admin -d "$DB"
            # remove the default admin/admin created by config init, unless our user IS admin
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
  sops.secrets = lib.concatMapAttrs (name: cfg: {
    "filebrowser/${name}/username" = { owner = cfg.user; };
    "filebrowser/${name}/password" = { owner = cfg.user; };
  }) instances;

  systemd.services = lib.mapAttrs' (name: cfg:
    lib.nameValuePair "filebrowser-${name}" (mkService name cfg)
  ) instances;

  services.caddy.virtualHosts = lib.mapAttrs' (name: cfg:
    lib.nameValuePair "${name}.metatron" {
      extraConfig = "tls internal\nreverse_proxy localhost:${toString cfg.port}";
    }
  ) instances;
}
