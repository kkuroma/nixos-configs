{ ... }:
{
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    host = "127.0.0.1";
    settings = {
      dns = {
        bind_hosts = [ "100.107.220.115" ];
        port = 53;
        upstream_dns = [
          "https://dns.mullvad.net/dns-query"
        ];
        bootstrap_dns = [ "1.1.1.1" "8.8.8.8" ];
        rewrites = [
          { domain = "*.metatron"; answer = "100.107.220.115"; }
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
