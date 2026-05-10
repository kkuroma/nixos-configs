{ pkgs, config, lib, ... }:
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
    user = "kuroma";
    dataDir = "/home/kuroma";
    settings.devices = {
      raziel.id   = "3ZJIJ5F-RXGMC73-5XKGWER-SGFSJSE-H3DKE54-KIR2OHU-UDXA4RG-7YIV7AP";
      zaphkiel.id = "V6IXQRC-MQEAYRQ-2IYU5WB-W5PF2AI-6CCWJSO-KCIRGR7-43DHLD4-K6RDTQA";
    };
    settings.folders."Documents" = {
      path = "/home/kuroma/Documents";
      devices = [ "raziel" "zaphkiel" ];
    };
    settings.folders."PrismInstances" = {
      path = "/home/kuroma/.local/share/PrismLauncher/instances";
      devices = [ "raziel" "zaphkiel" ];
    };
    settings.folders."Wallpapers" = {
      path = "/home/kuroma/Pictures/Wallpapers";
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
        /home/kuroma/.config/syncthing/config.xml)
      password=$(cat ${config.sops.secrets."syncthing/password".path})
      ${pkgs.curl}/bin/curl -sf -X PATCH \
        -H "X-API-Key: $api_key" \
        -H "Content-Type: application/json" \
        http://127.0.0.1:8384/rest/config/gui \
        -d "{\"password\":\"$password\"}"
    '';
    in lib.mkForce [ "${script}" ];
}
