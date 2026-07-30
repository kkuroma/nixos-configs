{ config, pkgs, ... }:
{
  sops.secrets."wireguard/yggdrasil/private-key" = { };
  sops.secrets."wireguard/yggdrasil/preshared-key" = { };
  sops.secrets."wireguard/yggdrasil/ip" = { };

  sops.templates."wg-yggdrasil.env".content = ''
    WG_PRIVKEY=${config.sops.placeholder."wireguard/yggdrasil/private-key"}
    WG_PSK=${config.sops.placeholder."wireguard/yggdrasil/preshared-key"}
    WG_ENDPOINT_IP=${config.sops.placeholder."wireguard/yggdrasil/ip"}
  '';

  # Allow wireguard access
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw 1 -s 10.10.30.0/24 -m conntrack --ctstate NEW -j nixos-fw-refuse
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 10.10.30.0/24 -m conntrack --ctstate NEW -j nixos-fw-refuse 2>/dev/null || true
  '';

  # Allow local traffic
  networking.localCommands = ''
    ip rule del to 10.10.0.0/16 lookup main priority 5200 2>/dev/null || true
    ip rule add to 10.10.0.0/16 lookup main priority 5200
  '';

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.templates."wg-yggdrasil.env".path ];

    profiles.yggdrasil = {
      connection = {
        id = "YggdrasilWG";
        type = "wireguard";
        interface-name = "ygg0";
        autoconnect = false;
      };

      wireguard.private-key = "$WG_PRIVKEY";

      "wireguard-peer.btQ0rdGVuz9kWBq2BM/LaGtxEa/vuxxh8QBVuHwidyc=" = {
        endpoint = "$WG_ENDPOINT_IP:51820";
        preshared-key = "$WG_PSK";
        preshared-key-flags = "0";
        allowed-ips = "10.10.0.0/16;"; # split tunnel to allow for local access
      };

      ipv4 = {
        address1 = "10.10.91.67/32";
        method = "manual";
        never-default = "true";
      };

      ipv6.method = "disabled";
    };
  };

  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeShellScript "ygg0-wg-endpoint-carveout" ''
      iface="$1"; action="$2"
      [ "$iface" = "ygg0" ] || exit 0
      ip="${pkgs.iproute2}/bin/ip"
      endpoint=$(cat ${config.sops.secrets."wireguard/yggdrasil/ip".path} 2>/dev/null) || exit 0
      [ -n "$endpoint" ] || exit 0
      case "$action" in
        up)
          $ip rule show | grep -q "5260:.*$endpoint" \
            || $ip rule add to "$endpoint/32" lookup main priority 5260
          ;;
        down)
          $ip rule del to "$endpoint/32" lookup main priority 5260 2>/dev/null || true
          ;;
      esac
    '';
  }];
}
