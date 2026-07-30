{ config, lib, pkgs, ... }:

# Scheduled ClamAV scanning with quarantine
  cfg = config.host.clamav;

  logDir = "/var/log/clamav";
  scanLog = "${logDir}/scan.log";

  # Email notification
  notifyScript = pkgs.writeShellScript "clamav-notify-email" ''
    subject="$1"
    {
      printf 'From: ${config.networking.hostName} ClamAV <noreply@${config.networking.hostName}>\r\n'
      printf 'To: ${toString cfg.notifyEmail}\r\n'
      printf 'Subject: %s\r\n' "$subject"
      printf 'Content-Type: text/plain\r\n\r\n'
      printf 'ClamAV on ${config.networking.hostName} flagged infected file(s).\n'
      printf 'They were moved to ${cfg.quarantineDir}.\n\n'
      printf -- '--- tail of ${scanLog} ---\n'
      ${pkgs.coreutils}/bin/tail -n 40 ${scanLog} 2>/dev/null || true
    } | ${pkgs.msmtp}/bin/msmtp --file=${config.sops.templates."msmtp-clamav".path} "${toString cfg.notifyEmail}"
  '';

  scanScript = pkgs.writeShellScript "clamav-scan" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.clamav pkgs.coreutils ]}:$PATH

    # Skip paths that aren't present/mounted yet instead of scanning an empty stub.
    targets=()
    for p in ${lib.escapeShellArgs cfg.paths}; do
      if [ -d "$p" ]; then
        targets+=("$p")
      else
        echo "clamav-scan: skipping missing path $p" >&2
      fi
    done
    if [ ''${#targets[@]} -eq 0 ]; then
      echo "clamav-scan: no scan paths present, nothing to do" >&2
      exit 0
    fi

    # --fdpass: this (root) client opens the files and hands clamd the fds, so the
    # unprivileged clamav daemon never needs read access to ct/pt data. --move
    # relocates infected files (needs write on the source dirs, hence root).
    set +e
    clamdscan --multiscan --fdpass --infected --move=${cfg.quarantineDir} --log=${scanLog} "''${targets[@]}"
    rc=$?
    set -e

    case "$rc" in
      0) echo "clamav-scan: clean" >&2 ;;
      1)
        echo "clamav-scan: INFECTED file(s) found, moved to ${cfg.quarantineDir}" >&2
        ${lib.optionalString (cfg.notifyEmail != null)
          ''${notifyScript} "[${config.networking.hostName}] ClamAV found infected files on the NAS" || true''}
        ;;
      *) echo "clamav-scan: clamdscan error (rc=$rc); is clamd running?" >&2 ;;
    esac
    # Detection is a successful job, not a unit failure; let the timer keep going.
    exit 0
  '';

  # zfs and vault are both ZFS pools, so anchor with zfs-mount.service
  storageAfter = if cfg.storage == "none" then [ ] else [ "zfs-mount.service" ];
in
{
  options.host.clamav = {
    enable = lib.mkEnableOption "scheduled ClamAV NAS scanning with quarantine";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories scanned recursively on each run.";
    };

    quarantineDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/clamav-quarantine";
      description = "Infected files are moved here (created 0700 root).";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd OnCalendar expression for the scan timer.";
    };

    storage = lib.mkOption {
      type = lib.types.enum [ "zfs" "vault" "none" ];
      default = "none";
      description = "Storage the scan waits on (orders after zfs-mount.service).";
    };

    notifyEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "If set, email this address via zoho/msmtp when a scan finds something.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.clamav.daemon = {
      enable = true;
      settings = {
        # Defaults silently skip files >25M, useless for a NAS, raise for large archives
        MaxFileSize = "1000M";
        MaxScanSize = "2048M";
        MaxRecursion = 16;
        MaxFiles = 50000;
      };
    };
    services.clamav.updater.enable = true;

    systemd.tmpfiles.rules = [
      "d ${cfg.quarantineDir} 0700 root root -"
    ];

    sops = lib.mkIf (cfg.notifyEmail != null) {
      secrets."vaultwarden/smtp-password".mode = lib.mkDefault "0444";
      templates."msmtp-clamav" = {
        mode = "0444";
        content = ''
          account default
          host smtp.zoho.com
          port 587
          tls on
          tls_starttls on
          auth on
          user contact@kuroma.dev
          password ${config.sops.placeholder."vaultwarden/smtp-password"}
          from contact@kuroma.dev
          logfile ${logDir}/msmtp.log
        '';
      };
    };

    systemd.services.clamav-scan = {
      description = "ClamAV scheduled scan with quarantine";
      after = [ "clamav-daemon.service" ] ++ storageAfter;
      requires = [ "clamav-daemon.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${scanScript}";
        LogsDirectory = "clamav";
        ProtectSystem = "strict"; # root, but boxed to exactly the dirs it must read+unlink from and quarantine into
        ReadWritePaths = cfg.paths ++ [ cfg.quarantineDir ];
        ProtectHome = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      };
    };

    systemd.timers.clamav-scan = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
      };
    };
  };
}
