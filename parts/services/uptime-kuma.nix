{ config, lib, pkgs, ... }:
let
  cfg = config.host.services.uptime-kuma or null;

  # One http monitor per enabled host.services entry with a port (= the caddy vhost set), probed on loopback
  # 200-399 accepted, several services answer / with a redirect (jellyfin, nextcloud, adguard, ...)
  monitored = lib.filterAttrs
    (n: s: s.enable && s.port != null && n != "uptime-kuma")
    config.host.services;

  toml = pkgs.formats.toml { };

  monitorsDir = pkgs.linkFarm "autokuma-static-monitors" (lib.mapAttrsToList
    (n: s: {
      name = "${n}.toml";
      path = toml.generate "${n}.toml" {
        type = "http";
        name = n;
        url = "http://localhost:${toString s.port}";
        interval = 60;
        max_retries = 3;
        accepted_statuscodes = [ "200-399" ];
      };
    })
    monitored);
in
lib.mkIf (cfg != null && cfg.enable) {
  services.uptime-kuma = {
    enable = true;
    settings.PORT = toString cfg.port;
  };

  # AutoKuma syncs the generated monitors into Kuma over its socket.io API
  sops.secrets."uptime-kuma/admin-username" = { };
  sops.secrets."uptime-kuma/admin-password" = { };

  sops.templates."autokuma-env".content = ''
    AUTOKUMA__KUMA__USERNAME=${config.sops.placeholder."uptime-kuma/admin-username"}
    AUTOKUMA__KUMA__PASSWORD=${config.sops.placeholder."uptime-kuma/admin-password"}
  '';

  systemd.services.autokuma = {
    description = "AutoKuma monitor sync";
    wantedBy = [ "multi-user.target" ];
    wants = [ "uptime-kuma.service" ];
    after = [ "uptime-kuma.service" "sops-install-secrets.service" ];

    environment = {
      AUTOKUMA__KUMA__URL = "http://localhost:${toString cfg.port}";
      AUTOKUMA__STATIC_MONITORS = "${monitorsDir}";
      AUTOKUMA__DOCKER__ENABLED = "false";
    };

    serviceConfig = {
      ExecStart = lib.getExe pkgs.autokuma;
      EnvironmentFile = config.sops.templates."autokuma-env".path;
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "30s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    };
  };
}
