{ config, lib, metatronIP, zaphkielIP, razielIP, ... }:
lib.mkIf (config.host.services.adguard or { enable = false; }).enable {
  # Admin credentials live in /var/lib/AdGuardHome/AdGuardHome.yaml under `users:`.
  # To set/reset: stop the service, edit the file, add a bcrypt hash for the password
  # (generate with: htpasswd -bnBC 10 "" yourpassword | tr -d ':\n'), then restart.
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    host = "127.0.0.1";
    settings = {
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [
          "https://dns.mullvad.net/dns-query"
        ];
        bootstrap_dns = [ "1.1.1.1" "8.8.8.8" ];
        rewrites = [
          { domain = "*.metatron";  answer = "${metatronIP}"; }
          { domain = "*.zaphkiel"; answer = "${zaphkielIP}"; }
          { domain = "*.raziel";   answer = "${razielIP}"; }
        ];
      };
      filters = [
        { 
          id = 1; 
          enabled = true; 
          name = "AdGuard DNS filter"; 
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"; 
        }
        { 
          id = 2; 
          enabled = true; 
          name = "OISD Big"; 
          url = "https://big.oisd.nl"; 
        }
        { 
          id = 3; 
          enabled = true; 
          name = "Hagezi Pro"; 
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"; 
        }
        { 
          id = 4; 
          enabled = true; 
          name = "Steven Black Unified"; 
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"; 
        }
      ];
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 53 ];
}
