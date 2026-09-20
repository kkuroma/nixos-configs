{ config, lib, pkgs, ... }:

let
  cfg = config.host.wireguard;

  fields = [
    "private-key"
    "address"
    "dns"
    "peer-public-key"
    "preshared-key"
    "allowed-ips"
    "endpoint"
  ];

  # Instance-scoped so two tunnels can't collide: one env file per tunnel, all loaded by one systemd unit.
  envVar = name: field:
    "WG_" + lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] "${name}_${field}");
  ref = name: field: "$" + envVar name field;

  secretPath = i: field: "${i.secretPrefix}/${field}";

  instances = lib.attrValues cfg;
in
{
  options.host.wireguard = lib.mkOption {
    default = { };
    description = "WireGuard tunnels, one NetworkManager profile each.";
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        interface = lib.mkOption {
          type = lib.types.str;
          default = "wg-${name}";
          description = "Link name, which is what the dispatcher script matches on.";
        };
        id = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "NetworkManager connection id (the profile is named after the attr key).";
        };
        autoconnect = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Bring the tunnel up at boot instead of by hand.";
        };
        secretPrefix = lib.mkOption {
          type = lib.types.str;
          default = "wireguard/${name}";
          description = "sops path holding the .conf fields.";
        };
        localSubnets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Kept on the main table, so an overlapping local LAN stays direct.";
        };
        refuseFrom = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Inbound sources refused by the firewall.";
        };
        localPriority = lib.mkOption {
          type = lib.types.int;
          default = 5200;
          description = "ip rule priority for localSubnets.";
        };
        endpointPriority = lib.mkOption {
          type = lib.types.int;
          default = 5260;
          description = "ip rule priority for the endpoint carve-out, must sit above tailscale's 5270.";
        };
      };
    }));
  };

  config = lib.mkIf (cfg != { }) {
    sops.secrets = lib.listToAttrs (lib.concatMap
      (i: map (f: lib.nameValuePair (secretPath i f) { }) fields)
      instances);

    sops.templates = lib.mapAttrs' (n: i: lib.nameValuePair "wg-${n}.env" {
      content = lib.concatMapStringsSep "\n"
        (f: "${envVar n f}=${config.sops.placeholder.${secretPath i f}}")
        fields;
    }) cfg;

    networking.networkmanager.ensureProfiles = {
      environmentFiles = lib.mapAttrsToList (n: _: config.sops.templates."wg-${n}.env".path) cfg;

      profiles = lib.mapAttrs (n: i: {
        connection = {
          inherit (i) id autoconnect;
          type = "wireguard";
          interface-name = i.interface;
        };

        wireguard.private-key = ref n "private-key";

        # envsubst rewrites the whole keyfile, section headers included.
        "wireguard-peer.${ref n "peer-public-key"}" = {
          endpoint = ref n "endpoint";
          preshared-key = ref n "preshared-key";
          preshared-key-flags = "0";
          allowed-ips = ref n "allowed-ips";
        };

        ipv4 = {
          address1 = ref n "address";
          dns = ref n "dns";
          method = "manual";
          never-default = "true";
        };

        ipv6.method = "disabled";
      }) cfg;
    };

    networking.firewall.extraCommands = lib.concatMapStrings
      (s: "iptables -I nixos-fw 1 -s ${s} -m conntrack --ctstate NEW -j nixos-fw-refuse\n")
      (lib.concatMap (i: i.refuseFrom) instances);

    networking.firewall.extraStopCommands = lib.concatMapStrings
      (s: "iptables -D nixos-fw -s ${s} -m conntrack --ctstate NEW -j nixos-fw-refuse 2>/dev/null || true\n")
      (lib.concatMap (i: i.refuseFrom) instances);

    networking.localCommands = lib.concatMapStrings
      (r: ''
        ip rule del to ${r.subnet} lookup main priority ${toString r.priority} 2>/dev/null || true
        ip rule add to ${r.subnet} lookup main priority ${toString r.priority}
      '')
      (lib.concatMap (i: map (s: { subnet = s; priority = i.localPriority; }) i.localSubnets) instances);

    # A Mullvad exit node puts `default dev tailscale0` in table 52, which would swallow the
    # handshake. Pin the endpoint to the physical route while the tunnel is up.
    networking.networkmanager.dispatcherScripts = lib.mapAttrsToList (n: i: {
      type = "basic";
      source = pkgs.writeShellScript "${i.interface}-wg-endpoint-carveout" ''
        iface="$1"; action="$2"
        [ "$iface" = "${i.interface}" ] || exit 0
        ip="${pkgs.iproute2}/bin/ip"
        endpoint=$(cat ${config.sops.secrets.${secretPath i "endpoint"}.path} 2>/dev/null) || exit 0
        host=''${endpoint%:*} # IPv4 literal, as the sops endpoint field is host:port
        [ -n "$host" ] || exit 0
        case "$action" in
          up)
            $ip rule show | grep -q "${toString i.endpointPriority}:.*$host" \
              || $ip rule add to "$host/32" lookup main priority ${toString i.endpointPriority}
            ;;
          down)
            $ip rule del to "$host/32" lookup main priority ${toString i.endpointPriority} 2>/dev/null || true
            ;;
        esac
      '';
    }) cfg;
  };
}
