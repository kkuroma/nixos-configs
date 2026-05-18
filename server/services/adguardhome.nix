{ pkgs, lib, config, ... }:
{
  sops.secrets."adguard/password" = {};

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      users = [];  # patched by preStart below
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

  # Patch users into the config after the module writes it (mutableSettings=false
  # always overwrites with empty users, so we inject the bcrypt hash every start)
  systemd.services.adguardhome = {
    after = [ "sops-install-secrets.service" ];
    preStart = lib.mkAfter ''
      password=$(cat ${config.sops.secrets."adguard/password".path})
      hash=$(${pkgs.whois}/bin/mkpasswd -m bcrypt "$password")
      ADGUARD_HASH="$hash" ${pkgs.yq-go}/bin/yq -i \
        '.users = [{"name": "admin", "password": strenv("ADGUARD_HASH")}]' \
        /var/lib/AdGuardHome/AdGuardHome.yaml
    '';
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 53 ];
}
