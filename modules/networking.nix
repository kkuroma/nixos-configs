{ ... }:
{
  networking.networkmanager.enable = true;

  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # tailscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-dns=true"
      "--exit-node-allow-lan-access=true"
    ];
  };
}
