{ ... }:
{
  networking.networkmanager.enable = true;

  # ssh reachable over tailscale only (sshd itself: ssh.nix)
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
