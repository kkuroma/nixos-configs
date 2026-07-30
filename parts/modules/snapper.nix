{ username, config, lib, ... }:
# Hourly btrfs snapshots of /home (desktops only)
lib.mkIf (config.host.profile == "desktop") {
  services.snapper.configs.home = {
    ALLOW_USERS = [ username ];
    SUBVOLUME = "/home";
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_MIN_AGE = 3600; # 60 minute lifetime before nuke
    TIMELINE_LIMIT_HOURLY = "6"; # keep the last 6 hours
    TIMELINE_LIMIT_DAILY = "1"; # keep the last day
  };
}
