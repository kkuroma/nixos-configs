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
          SNAP="backup-$(date +%Y%m%d-%H%M)"
          zfs snapshot "${localDataset}@$SNAP"
          zfs list -H -t snapshot -o name ${localDataset} \
            | sed 's|${localDataset}@||' | sort > /tmp/zfs-snaps-local-${name}
          ssh metatron zfs list -H -t snapshot -o name ${remoteDataset} 2>/dev/null \
            | sed 's|${remoteDataset}@||' | sort > /tmp/zfs-snaps-remote-${name} || true
          LAST_COMMON=$(comm -12 /tmp/zfs-snaps-local-${name} /tmp/zfs-snaps-remote-${name} | tail -1)
          rm -f /tmp/zfs-snaps-local-${name} /tmp/zfs-snaps-remote-${name}
          if [ -n "$LAST_COMMON" ]; then
            zfs send -i "${localDataset}@$LAST_COMMON" "${localDataset}@$SNAP" \
              | ssh metatron zfs receive -F ${remoteDataset}
          else
            zfs send "${localDataset}@$SNAP" | ssh metatron zfs receive -F ${remoteDataset}
          fi
          # Keep only last 3 backup snapshots locally
          zfs list -H -t snapshot -o name ${localDataset} \
            | grep '@backup-' | head -n -3 | xargs -r zfs destroy
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
    { 
      name = "research";
      localDataset = "vault/research";
      remoteDataset = "tank/research";
      oncalendar = "*-*-* 03,09,15,21:00:00";
    }
  ];

  allEntries = (map mkRsyncBackup rsyncJobs) ++ (map mkZfsBackup zfsJobs);
in
builtins.foldl' (acc: entry: {
  systemd.services = acc.systemd.services // entry.systemd.services;
  systemd.timers   = acc.systemd.timers   // entry.systemd.timers;
}) { systemd.services = {}; systemd.timers = {}; } allEntries
