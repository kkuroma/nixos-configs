{ pkgs, config, ... }:
{
  sops.secrets."adguard/password" = { mode = "0444"; };

  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    host = "127.0.0.1";
    settings = {
      dns = {
        bind_hosts = [ "100.107.220.115" ];
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
      # users intentionally omitted — managed by adguardhome-password.service
    };
  };

  # Runs before adguardhome.service so yaml-merge (in adguardhome's own preStart)
  # never sees a users key from Nix, leaving our patched value intact.
  systemd.services.adguardhome-password = {
    description = "Patch AdGuard Home admin password";
    wantedBy = [ "adguardhome.service" ];
    before = [ "adguardhome.service" ];
    after = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "+${pkgs.writeShellScript "adguard-set-password" ''
        set -euo pipefail
        yaml=/var/lib/AdGuardHome/AdGuardHome.yaml
        [ -e "$yaml" ] || echo 'users: []' > "$yaml"
        password=$(cat ${config.sops.secrets."adguard/password".path})
        hash=$(${pkgs.mkpasswd}/bin/mkpasswd -m bcrypt "$password")
        ADGUARD_HASH="$hash" ${pkgs.yq-go}/bin/yq -i \
          '.users = [{"name": "admin", "password": strenv("ADGUARD_HASH")}]' \
          "$yaml"
      ''}";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 53 ];
}
