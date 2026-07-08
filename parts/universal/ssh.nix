# One sshd policy for every host; port 22 opens on tailscale0 only (networking.nix).
# Host-specific extras (e.g. metatron's GatewayPorts) stay in that host's configuration.nix.
{ ... }:
{
  # Terminfo for all terminal emulators (ghostty/kitty/wezterm/...) so SSH
  # sessions from any client render correctly on headless hosts too.
  environment.enableAllTerminfo = true;

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
