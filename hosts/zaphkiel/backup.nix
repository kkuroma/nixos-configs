{ pkgs, username, ... }:
let
  mkBackup = { name, script, oncalendar }: {
    systemd.services."backup-${name}" = {
      description = "Backup ${name}";
      serviceConfig = {
        Type = "oneshot";
        User = username;
        ExecStart = pkgs.writeShellScript "backup-${name}" script;
        # Prevent concurrent runs if timer fires while previous is still running
        TimeoutStartSec = "6h";
      };
      path = [ pkgs.rsync ];
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

  jobs = [
    {
      name = "home";
      oncalendar = "*-*-* 00,06,12,18:00:00";
      script = ''
        set -euo pipefail
        SOURCE="/home/${username}/"
        DEST="/mnt/NAS/kuroma/"
        MOUNT_POINT="/mnt/NAS"

        if ! mountpoint -q "$MOUNT_POINT"; then
          echo "Error: $MOUNT_POINT is not mounted. Aborting." >&2
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
          "$SOURCE" "$DEST" &&
          echo "Backup completed at $(date)" ||
          { echo "Backup failed." >&2; exit 1; }
      '';
    }
    {
      name = "songs";
      oncalendar = "*-*-* 01,07,13,19:00:00";
      script = ''
        set -euo pipefail
        rsync -av --delete /mnt/Vault-Storage/songs/ /mnt/NAS/music/
      '';
    }
    {
      name = "anime";
      oncalendar = "*-*-* 02,08,14,20:00:00";
      script = ''
        set -euo pipefail
        rsync -av --delete /mnt/Vault-Storage/anime/ /mnt/NAS/anime/
      '';
    }
  ];
in
builtins.foldl' (acc: job:
  let entry = mkBackup job;
  in {
    systemd.services = acc.systemd.services // entry.systemd.services;
    systemd.timers   = acc.systemd.timers   // entry.systemd.timers;
  }
) { systemd.services = {}; systemd.timers = {}; } jobs
