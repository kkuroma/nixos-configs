{ pkgs, lib, ... }:

let
  datasets = {
    "tank/media/anime" = {
      mountpoint = "/tank/media/anime";
      quota = "3T";
      reservation = "3T";
    };
    "tank/media/music" = {
      mountpoint = "/tank/media/music";
      quota = "1T";
      reservation = "1T";
    };
    "tank/nas/kuroma" = {
      mountpoint = "/tank/nas/kuroma";
      quota = "1T";
      reservation = "1T";
    };
    "tank/nas/ct" = {
      mountpoint = "/tank/nas/ct";
      quota = "1T";
      reservation = "1T";
    };
    "tank/nas/pt" = {
      mountpoint = "/tank/nas/pt";
      quota = "1T";
      reservation = "1T";
    };
    "tank/nas/public" = {
      mountpoint = "/tank/nas/public";
      quota = "2T";
      reservation = "2T";
    };
    "tank/services/nextcloud" = {
      mountpoint = "/tank/services/nextcloud";
      quota = "1T";
      reservation = "1T";
    };
    "tank/services/matrix" = {
      mountpoint = "/tank/services/matrix";
      quota = "512G";
      reservation = "512G";
    };
    "tank/backups" = {
      mountpoint = "/tank/backups";
      quota = null;
      reservation = null;
    };
  };

  mkDataset = name: cfg: ''
    zfs create -p -o mountpoint=${cfg.mountpoint} ${name} 2>/dev/null || true
    ${lib.optionalString (cfg.quota != null) "zfs set quota=${cfg.quota} ${name}"}
    ${lib.optionalString (cfg.reservation != null) "zfs set reservation=${cfg.reservation} ${name}"}
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
