{ config, lib, ... }:
let
  cfg = config.host.services.cockpit or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  services.cockpit = {
    enable = true;
    settings.WebService = {
      AllowUnencrypted = "true";
      Origins = lib.mkForce "https://cockpit.${config.networking.hostName}";
    };
  };

  security.pam.services.cockpit = {};
}
