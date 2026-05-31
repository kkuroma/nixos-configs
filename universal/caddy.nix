{ ... }:
{
  services.caddy.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 443 ];

  security.pki.certificateFiles = [
    ../certs/metatron.pem
    ../certs/zaphkiel.pem
    ../certs/raziel.pem
  ];
}
