{ ... }:
{
  services.caddy.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 443 ];
}
