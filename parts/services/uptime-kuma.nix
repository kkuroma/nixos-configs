{ config, lib, ... }:
let
  cfg = config.host.services.uptime-kuma or null;
in
{
  # Monitors, notifications, and the admin account are GUI-managed by choice;
  # state lives in /var/lib/uptime-kuma (StateDirectory)
  services.uptime-kuma = lib.mkIf (cfg != null && cfg.enable) {
    enable = true;
    settings.PORT = toString cfg.port;
  };
}
