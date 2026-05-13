{ pkgs, config, lib, username, ... }:
{
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

  # syncthing
  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    settings.devices = {
      raziel.id   = "3ZJIJ5F-RXGMC73-5XKGWER-SGFSJSE-H3DKE54-KIR2OHU-UDXA4RG-7YIV7AP";
      zaphkiel.id = "V6IXQRC-MQEAYRQ-2IYU5WB-W5PF2AI-6CCWJSO-KCIRGR7-43DHLD4-K6RDTQA";
    };
    settings.folders."Documents" = {
      path = "/home/${username}/Documents";
      devices = [ "raziel" "zaphkiel" ];
    };
    settings.folders."PrismInstances" = {
      path = "/home/${username}/.local/share/PrismLauncher/instances";
      devices = [ "raziel" "zaphkiel" ];
    };
    settings.folders."Wallpapers" = {
      path = "/home/${username}/Pictures/Wallpapers";
      devices = [ "raziel" "zaphkiel" ];
    };
  };

  # Set Syncthing GUI password from sops secret
  systemd.services.syncthing.serviceConfig.ExecStartPost =
    let script = pkgs.writeShellScript "syncthing-set-password" ''
      for i in $(seq 30); do
        ${pkgs.curl}/bin/curl -sf http://127.0.0.1:8384/rest/noauth/health >/dev/null && break
        sleep 1
      done
      api_key=$(${pkgs.libxml2}/bin/xmllint --xpath 'string(//apikey)' \
        /home/${username}/.config/syncthing/config.xml)
      password=$(cat ${config.sops.secrets."syncthing/password".path})
      ${pkgs.curl}/bin/curl -sf -X PATCH \
        -H "X-API-Key: $api_key" \
        -H "Content-Type: application/json" \
        http://127.0.0.1:8384/rest/config/gui \
        -d "{\"password\":\"$password\"}"
    '';
    in lib.mkForce [ "${script}" ];

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
