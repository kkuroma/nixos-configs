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

      # Public: cloudflared tunnels to localhost:80, Caddy routes by Host
      "http://searx.kuroma.dev".extraConfig = "reverse_proxy localhost:8888";
      "http://pdf.kuroma.dev".extraConfig = "reverse_proxy localhost:8085";
      "http://pastebin.kuroma.dev".extraConfig = "reverse_proxy localhost:8082";
    };
  };

  # 80 for cloudflared public ingress, 443 for internal HTTPS
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 443 ];
}
