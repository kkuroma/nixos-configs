{ pkgs, username, ... }:
let
  mkRsyncBackup = { name, script, oncalendar }: {
    systemd.services."backup-${name}" = {
      description = "Backup ${name}";
      serviceConfig = {
        Type = "oneshot";
        User = username;
        ExecStart = pkgs.writeShellScript "backup-${name}" script;
        TimeoutStartSec = "6h";
      };
      path = [ pkgs.rsync pkgs.util-linux ];
    };
    systemd.timers."backup-${name}" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = oncalendar;
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };

  mkZfsBackup = { name, localDataset, remoteDataset, oncalendar }: {
    systemd.services."backup-${name}" = {
      description = "ZFS backup ${name} to metatron";
      serviceConfig = {
        Type = "oneshot";
        User = username;
        ExecStart = pkgs.writeShellScript "backup-${name}-zfs" ''
          set -euo pipefail
          LOCAL_LATEST=$(zfs list -H -t snapshot -o name ${localDataset} | tail -1)
          if [ -z "$LOCAL_LATEST" ]; then
            echo "No local snapshots found on ${localDataset}, skipping." >&2
            exit 0
          fi
          REMOTE_LATEST=$(ssh metatron zfs list -H -t snapshot -o name ${remoteDataset} 2>/dev/null | tail -1 | sed 's|${remoteDataset}@||' || true)
          if [ -n "$REMOTE_LATEST" ]; then
            zfs send -I "${localDataset}@$REMOTE_LATEST" "$LOCAL_LATEST" \
              | ssh metatron zfs receive -F ${remoteDataset}
          else
            zfs send "$LOCAL_LATEST" | ssh metatron zfs receive -F ${remoteDataset}
          fi
        '';
        TimeoutStartSec = "6h";
      };
      path = [ pkgs.zfs pkgs.openssh ];
    };
    systemd.timers."backup-${name}" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = oncalendar;
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };

  rsyncJobs = [
    {
      name = "research";
      oncalendar = "*-*-* 03,09,15,21:00:00";
      script = ''
        set -euo pipefail
        rsync -aHAXx --ignore-errors \
          /mnt/Vault-Storage/research/ \
          metatron:/tank/research/
      '';
    }
    {
      name = "home";
      oncalendar = "*-*-* 00,06,12,18:00:00";
      script = ''
        set -euo pipefail
        if ! mountpoint -q /mnt/NAS; then
          echo "Error: /mnt/NAS is not mounted. Aborting." >&2
          exit 1
        fi
        rsync -av --delete \
          --exclude='.cache/' \
          --exclude='.local/share/Trash/' \
          --exclude='.Trash-*' \
          --exclude='Downloads/' \
          --exclude='node_modules/' \
          --exclude='*.tmp' \
          --exclude='.gvfs/' \
          /home/${username}/ /mnt/NAS/kuroma/home/
      '';
    }
  ];

  zfsJobs = [
    {
      name = "anime";
      localDataset = "vault/media/anime";
      remoteDataset = "tank/media/anime";
      oncalendar = "*-*-* 02,08,14,20:00:00";
    }
    {
      name = "music";
      localDataset = "vault/media/music";
      remoteDataset = "tank/media/music";
      oncalendar = "*-*-* 01,07,13,19:00:00";
    }
  ];

  allEntries = (map mkRsyncBackup rsyncJobs) ++ (map mkZfsBackup zfsJobs);
in
builtins.foldl' (acc: entry: {
  systemd.services = acc.systemd.services // entry.systemd.services;
  systemd.timers   = acc.systemd.timers   // entry.systemd.timers;
}) { systemd.services = {}; systemd.timers = {}; } allEntries
