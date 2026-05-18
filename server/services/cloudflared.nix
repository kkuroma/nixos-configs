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
      - hostname: cloud.kuroma.dev
        service: http://localhost:80
      - hostname: matrix.isomorphic.to
        service: http://localhost:80
      - service: http_status:404
  '';
in
{
  sops.secrets."cloudflared/token" = { mode = "0444"; };
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
