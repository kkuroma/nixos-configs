# One sshd policy for every host; port 22 opens on tailscale0 only (networking.nix).
# Host-specific extras (e.g. metatron's GatewayPorts) stay in that host's configuration.nix.
{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
