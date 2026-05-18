{ lib, config, ... }:
{
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    settings = {
      http.address = "127.0.0.1:3000";
      dns = {
        bind_hosts = [ "100.107.220.115" ];  # tailscale0 only, avoids conflict with systemd-resolved
        port = 53;
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
        ];
        bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
        rewrites = [
          { domain = "*.metatron"; answer = "100.107.220.115"; }
        ];
      };
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 53 ];
}
