{ pkgs, lib, ... }:

let
  datasets = {
    "tank/media/anime" = {
      mountpoint = "/tank/media/anime";
      quota = "3T";
      reservation = "3T";
      owner = "kuroma";
      group = "media";
      mode = "775";
    };
    "tank/media/music" = {
      mountpoint = "/tank/media/music";
      quota = "1T";
      reservation = "1T";
      owner = "kuroma";
      group = "media";
      mode = "775";
    };
    "tank/nas/kuroma" = {
      mountpoint = "/tank/nas/kuroma";
      quota = "1T";
      reservation = "1T";
      owner = "kuroma";
      group = "users";
      mode = "700";
    };
    "tank/nas/ct" = {
      mountpoint = "/tank/nas/ct";
      quota = "1T";
      reservation = "1T";
      owner = "ct";
      group = "family";
      mode = "770";
    };
    "tank/nas/pt" = {
      mountpoint = "/tank/nas/pt";
      quota = "1T";
      reservation = "1T";
      owner = "pt";
      group = "family";
      mode = "770";
    };
    "tank/nas/public" = {
      mountpoint = "/tank/nas/public";
      quota = "2T";
      reservation = "2T";
      owner = "kuroma";
      group = "family";
      mode = "775";
    };
    "tank/services/nextcloud" = {
      mountpoint = "/tank/services/nextcloud";
      quota = "1T";
      reservation = "1T";
      owner = "nextcloud";
      group = "nextcloud";
      mode = "700";
    };
    "tank/services/matrix" = {
      mountpoint = "/tank/services/matrix";
      quota = "512G";
      reservation = "512G";
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "700";
    };
    "tank/services/jellyfin" = {
      mountpoint = "/tank/services/jellyfin";
      quota = "50G";
      reservation = "50G";
      owner = "jellyfin";
      group = "media";
      mode = "755";
    };
    "tank/services/navidrome" = {
      mountpoint = "/tank/services/navidrome";
      quota = "5G";
      reservation = "5G";
      owner = "navidrome";
      group = "navidrome";
      mode = "700";
    };
    "tank/services/privatebin" = {
      mountpoint = "/tank/services/privatebin";
      quota = "5G";
      reservation = "5G";
      owner = "privatebin";
      group = "privatebin";
      mode = "700";
    };
    "tank/services/postgresql" = {
      mountpoint = "/tank/services/postgresql";
      quota = "32G";
      reservation = "32G";
      owner = "postgres";
      group = "postgres";
      mode = "700";
    };
    "tank/services/vaultwarden" = {
      mountpoint = "/tank/services/vaultwarden";
      quota = "2G";
      reservation = "2G";
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "700";
    };
    "tank/services/forgejo" = {
      mountpoint = "/tank/services/forgejo";
      quota = "256G";
      reservation = "256G";
      owner = "forgejo";
      group = "forgejo";
      mode = "750";
    };
    "tank/research" = {
      mountpoint = "/tank/research";
      quota = "12T";
      reservation = "12T";
      owner = "kuroma";
      group = "users";
      mode = "700";
    };
    "tank/backups" = {
      mountpoint = "/tank/backups";
      quota = null;
      reservation = null;
      owner = "kuroma";
      group = "users";
      mode = "700";
    };
  };

  mkDataset = name: cfg: ''
    zfs create -p -o mountpoint=${cfg.mountpoint} ${name} 2>/dev/null || true
    ${lib.optionalString (cfg.quota != null) "zfs set quota=${cfg.quota} ${name}"}
    ${lib.optionalString (cfg.reservation != null) "zfs set reservation=${cfg.reservation} ${name}"}
    ${lib.optionalString (name == "tank/services/postgresql") "zfs set recordsize=8k ${name}"}
    chown ${cfg.owner}:${cfg.group} ${cfg.mountpoint} 2>/dev/null || true
    chmod ${cfg.mode} ${cfg.mountpoint}
  '';
in
{
  systemd.services.zfs-datasets = {
    description = "Create and configure ZFS datasets";
    after = [ "zfs-import-tank.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.zfs ];
    script = lib.concatStrings (lib.mapAttrsToList mkDataset datasets);
  };

  users.groups.family = {};
  users.groups.media.members = [ "kuroma" "jellyfin" "navidrome" ];

  users.users.ct = {
    uid = 1001;
    isSystemUser = true;
    group = "family";
    description = "NAS user (smb only no shell)";
  };

  users.users.pt = {
    uid = 1002;
    isSystemUser = true;
    group = "family";
    description = "NAS user (smb only no shell)";
  };
}
