{ pkgs, config, lib, username, ... }:
{
  services.caddy.virtualHosts."syncthing.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8384";

  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    settings.gui.insecureSkipHostcheck = true;
    settings.devices = {
      raziel = {
        id = "3ZJIJ5F-RXGMC73-5XKGWER-SGFSJSE-H3DKE54-KIR2OHU-UDXA4RG-7YIV7AP";
        addresses = [ "tcp://100.79.72.120:22000" "dynamic" ];
      };
      zaphkiel = {
        id = "V6IXQRC-MQEAYRQ-2IYU5WB-W5PF2AI-6CCWJSO-KCIRGR7-43DHLD4-K6RDTQA";
        addresses = [ "tcp://100.91.235.104:22000" "dynamic" ];
      };
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

  systemd.services.syncthing.serviceConfig.ExecStartPost =
    let script = pkgs.writeShellScript "syncthing-set-password" ''
      for i in $(seq 30); do
        ${pkgs.curl}/bin/curl -sf http://127.0.0.1:8384/rest/noauth/health >/dev/null && break
        sleep 1
      done
      api_key=$(${pkgs.libxml2}/bin/xmllint --xpath 'string(//apikey)' /home/${username}/.config/syncthing/config.xml)
      password=$(cat ${config.sops.secrets."syncthing/password".path})
      ${pkgs.curl}/bin/curl -sf -X PATCH -H "X-API-Key: $api_key" -H "Content-Type: application/json" http://127.0.0.1:8384/rest/config/gui -d "{\"password\":\"$password\"}"
    '';
    in lib.mkForce [ "${script}" ];
}
