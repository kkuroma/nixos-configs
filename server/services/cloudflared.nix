{ pkgs, config, lib, ... }:
let
  tunnelConfig = pkgs.writeText "cloudflared-config.yaml" ''
    ingress:
      - hostname: searx.kuroma.dev
        service: http://localhost:80
      - hostname: pdf.kuroma.dev
        service: http://localhost:80
      - hostname: pastebin.kuroma.dev
        service: http://localhost:80
      - service: http_status:404
  '';
in
{
  sops.secrets."cloudflared/token" = { mode = "0444"; };
  sops.secrets."cloudflared/tunnel" = { mode = "0444"; };

  systemd.services.cloudflare-dns = {
    description = "Register Cloudflare tunnel DNS routes";
    after = [ "network-online.target" "sops-install-secrets.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.cloudflared ];
    script = ''
      TOKEN=$(cat ${config.sops.secrets."cloudflared/token".path})
      TUNNEL=$(cat ${config.sops.secrets."cloudflared/tunnel".path})
      for host in searx.kuroma.dev pdf.kuroma.dev pastebin.kuroma.dev; do
        cloudflared tunnel --token "$TOKEN" route dns "$TUNNEL" "$host" || true
      done
    '';
  };

  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "sops-install-secrets.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.writeShellScript "cloudflared-start" ''
        exec ${pkgs.cloudflared}/bin/cloudflared tunnel \
          --no-autoupdate \
          --config ${tunnelConfig} \
          run --token "$(cat ${config.sops.secrets."cloudflared/token".path})"
      ''}";
      Restart = "always";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };
}
