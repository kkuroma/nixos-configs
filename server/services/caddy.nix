{ ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts = {
      # Internal — *.metatron resolves via AdGuard to tailscale IP, Caddy routes by Host
      "http://jellyfin.metatron".extraConfig    = "reverse_proxy localhost:8096";
      "http://navidrome.metatron".extraConfig   = "reverse_proxy localhost:4533";
      "http://adguard.metatron".extraConfig     = "reverse_proxy localhost:3000";
      "http://searx.metatron".extraConfig       = "reverse_proxy localhost:8888";
      "http://pdf.metatron".extraConfig         = "reverse_proxy localhost:8085";
      "http://pastebin.metatron".extraConfig    = "reverse_proxy localhost:8082";

      # Public — cloudflared tunnels these to localhost:80, Caddy routes by Host
      "http://searx.kuroma.dev".extraConfig     = "reverse_proxy localhost:8888";
      "http://pdf.kuroma.dev".extraConfig       = "reverse_proxy localhost:8085";
      "http://pastebin.kuroma.dev".extraConfig  = "reverse_proxy localhost:8082";
    };
  };

  # Port 80 on tailscale0 for internal *.metatron access
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 ];
}
