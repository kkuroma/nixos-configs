{ ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts = {
      # Internal: *.metatron — HTTPS via Caddy local CA (tls internal)
      "jellyfin.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8096";
      "navidrome.metatron".extraConfig = "tls internal\nreverse_proxy localhost:4533";
      "adguard.metatron".extraConfig = "tls internal\nreverse_proxy localhost:3000";
      "searx.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8888";
      "pdf.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8085";
      "pastebin.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8082";
      "nextcloud.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8081";
      "matrix.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8448";

      # Public: cloudflared tunnels to localhost:80, Caddy routes by Host
      "http://searx.kuroma.dev".extraConfig = "reverse_proxy localhost:8888";
      "http://pdf.kuroma.dev".extraConfig = "reverse_proxy localhost:8085";
      "http://pastebin.kuroma.dev".extraConfig = "reverse_proxy localhost:8082";
      "http://cloud.kuroma.dev".extraConfig = "reverse_proxy localhost:8081";
      "http://matrix.isomorphic.to".extraConfig = ''
        handle /.well-known/matrix/server {
          header Content-Type application/json
          respond `{"m.server":"matrix.isomorphic.to:443"}` 200
        }
        handle /.well-known/matrix/client {
          header Content-Type application/json
          header Access-Control-Allow-Origin *
          respond `{"m.homeserver":{"base_url":"https://matrix.isomorphic.to"}}` 200
        }
        handle {
          reverse_proxy localhost:8448
        }
      '';
    };

    # Filebrowser: 1 instances per port (8200++)
    "ct-dump.metatron".extraConfig = "tls internal\nreverse_proxy localhost:8200";
    "http://ct-dump.kuroma.dev".extraConfig = "reverse_proxy localhost:8200";
  };

  # 80 for cloudflared public ingress, 443 for internal HTTPS
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 443 ];
}
