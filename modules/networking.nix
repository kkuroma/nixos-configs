{ ... }:
{
  networking.networkmanager.enable = true;

  # firewall, will set up properly later i need 3000
  networking.firewall.allowedTCPPorts = [ 3000 ];

  # tailscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-dns=true"
      "--exit-node-allow-lan-access=true"
    ];
  };
}
