{ ... }:
{
  systemd.services.zfs-datasets = {
    description = "Create and configure ZFS datasets";
    after = [ "zfs-import-tank.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      zfs create -p -o mountpoint=/tank/media/anime       tank/media/anime
      zfs create -p -o mountpoint=/tank/media/music       tank/media/music

      zfs create -p -o mountpoint=/tank/nas/kuroma        tank/nas/kuroma
      zfs create -p -o mountpoint=/tank/nas/mom           tank/nas/mom
      zfs create -p -o mountpoint=/tank/nas/dad           tank/nas/dad
      zfs create -p -o mountpoint=/tank/nas/public        tank/nas/public

      zfs create -p -o mountpoint=/tank/services/nextcloud  tank/services/nextcloud
      zfs create -p -o mountpoint=/tank/services/matrix     tank/services/matrix

      zfs create -p -o mountpoint=/tank/backups           tank/backups

      zfs set quota=1T tank/nas/kuroma
      zfs set quota=1T tank/nas/mom
      zfs set quota=2T tank/nas/public
      zfs set quota=1T tank/nas/dad
    '';
  };

  users.groups.family = {};

  users.users.mom = {
    uid = 1001;
    isSystemUser = true;
    group = "family";
    description = "NAS user — SMB only, no shell";
  };

  users.users.dad = {
    uid = 1002;
    isSystemUser = true;
    group = "family";
    description = "NAS user — SMB only, no shell";
  };
}
