{ username, config, lib, ... }:
# Btrfs snapshots of /home every 3 hours (desktops only)
lib.mkIf (config.host.profile == "desktop") {
  services.snapper.snapshotInterval = "0/3:00:00";
  services.snapper.configs.home = {
    ALLOW_USERS = [ username ];
    SUBVOLUME = "/home";
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_MIN_AGE = 3600;
    TIMELINE_LIMIT_HOURLY = "8";
    TIMELINE_LIMIT_DAILY = "0";
    TIMELINE_LIMIT_WEEKLY = "1";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
  };
}
