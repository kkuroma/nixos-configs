{ config, pkgs, ... }:
# Yggdrasil - external server co-hosted with haruto, imports keys from the following
#   wireguard/yggdrasil/private-key
#   wireguard/yggdrasil/preshared-key
# NetworkManager-ensure-profiles runs envsubst over the profile with this env file.
{
  sops.secrets."wireguard/yggdrasil/private-key" = { };
  sops.secrets."wireguard/yggdrasil/preshared-key" = { };

  sops.templates."wg-yggdrasil.env".content = ''
    WG_PRIVKEY=${config.sops.placeholder."wireguard/yggdrasil/private-key"}
    WG_PSK=${config.sops.placeholder."wireguard/yggdrasil/preshared-key"}
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
        endpoint = "68.187.65.48:51820";
        preshared-key = "$WG_PSK";
        preshared-key-flags = "0";
        # Split tunnel: only 10.10.0.0/16 goes through; internet + tailscale stay
        # direct, and a local 10.10.x wifi wins by longest prefix. The dispatcher
        # below carves the endpoint out of any tailscale exit node.
        allowed-ips = "10.10.0.0/16;";
      };

      ipv4 = {
        address1 = "10.10.91.67/32";
        method = "manual";
        never-default = "true";
      };

      ipv6.method = "disabled";
    };
  };

  # Carve the wg endpoint out of the tailscale exit node. When the mullvad exit node is
  # active, table 52 holds `default dev tailscale0`, which would swallow the handshake
  # packets to 68.187.65.48. This rule (priority 5260, just below tailscale's `lookup 52`
  # at 5270) forces the endpoint out the physical default route instead. Tied to ygg0
  # up/down so it leaves no stray rule when the tunnel is off, and survives reboots +
  # tailscale restarts (tailscale never touches a rule it didn't create).
  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeShellScript "ygg0-wg-endpoint-carveout" ''
      iface="$1"; action="$2"
      [ "$iface" = "ygg0" ] || exit 0
      ip="${pkgs.iproute2}/bin/ip"
      case "$action" in
        up)
          $ip rule show | grep -q "5260:.*68.187.65.48" \
            || $ip rule add to 68.187.65.48/32 lookup main priority 5260
          ;;
        down)
          $ip rule del to 68.187.65.48/32 lookup main priority 5260 2>/dev/null || true
          ;;
      esac
    '';
  }];
}
