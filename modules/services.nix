{ username, config, lib, ... }:
lib.mkIf (config.host.profile == "desktop") {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.udisks2.enable = true;
  services.printing.enable = true;

  services.power-profiles-daemon.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Snapper (backup)
  # list all backups: snapper -c home list -> shows numbers like XX
  # snapper -c home undochange XX..0 -> reverts 0 (current) to XX
  # do as root
  services.snapper = {
    configs = {
      home = {
        ALLOW_USERS = [ username ];
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_MIN_AGE = 3600; # 60 minute lifetime before nuke
        TIMELINE_LIMIT_HOURLY = "6"; # keep the last 6 hours
        TIMELINE_LIMIT_DAILY = "1"; # keey tha last day
      };
    };
  };
}
