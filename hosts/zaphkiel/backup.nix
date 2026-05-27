{ pkgs, username, ... }:
let
  mkBackup = { name, script, oncalendar }: {
    systemd.services."backup-${name}" = {
      description = "Backup ${name}";
      serviceConfig = {
        Type = "oneshot";
        User = username;
        ExecStart = pkgs.writeShellScript "backup-${name}" script;
        TimeoutStartSec = "6h";
      };
      path = [ pkgs.rsync pkgs.openssh pkgs.util-linux ];
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
      name = "anime";
      oncalendar = "*-*-* 02,08,14,20:00:00";
      script = ''
        set -euo pipefail
        rsync -aHAXx --ignore-errors --info=progress2 --delete \
          /mnt/Vault-Storage/media/anime/ \
          metatron:/tank/media/anime/
      '';
    }
    {
      name = "music";
      oncalendar = "*-*-* 01,07,13,19:00:00";
      script = ''
        set -euo pipefail
        rsync -aHAXx --ignore-errors --info=progress2 --delete \
          /mnt/Vault-Storage/media/music/ \
          metatron:/tank/media/music/
      '';
    }
    {
      name = "research";
      oncalendar = "Sun *-*-* 03:00:00";
      script = ''
        set -euo pipefail
        rsync -aHAXx --ignore-errors --info=progress2 \
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
        rsync -aHAXx --ignore-errors --info=progress2 --delete \
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
in
builtins.foldl' (acc: entry: {
  systemd.services = acc.systemd.services // entry.systemd.services;
  systemd.timers   = acc.systemd.timers   // entry.systemd.timers;
}) { systemd.services = {}; systemd.timers = {}; } (map mkBackup jobs)
