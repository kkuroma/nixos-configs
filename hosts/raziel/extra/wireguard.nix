{ config, pkgs, ... }:
# Yggdrasil - external server co-hosted with haruto, imports keys from the following
#   wireguard/yggdrasil/private-key
# NetworkManager-ensure-profiles runs envsubst over the profile with this env file.
# The current (-Kuroma) peer has no preshared key, so none is templated here.
{
  sops.secrets."wireguard/yggdrasil/private-key" = { };

  sops.templates."wg-yggdrasil.env".content = ''
    WG_PRIVKEY=${config.sops.placeholder."wireguard/yggdrasil/private-key"}
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
        # Split tunnel over the whole internal 10.10.0.0/16 range (proxmox 10.10.30.10,
        # plus .20/.60/.91) — NOT 0.0.0.0/0, so internet stays direct and tailscale's
        # 100.64.0.0/10 is untouched. Local LAN subnets win by longest-prefix, so toggling
        # this up while on a 10.10.x wifi doesn't tunnel your own gateway. The wg endpoint
        # (68.187.65.48) is carved out of the tailscale exit node by the dispatcher below.
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
