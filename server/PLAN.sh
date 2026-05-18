#!/usr/bin/env bash
# metatron setup plan — run sections manually, not all at once
# ============================================================

# ============================================================
# PHASE 1: ZFS POOL
# ============================================================

# Boot NixOS installer, then:

# 1a. Partition + format NVMe (disko handles this)
sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  /path/to/hosts/metatron/disko.nix

# 1b. Create ZFS pool on sda-sdd (use by-id paths after checking)
# ls /dev/disk/by-id/ | grep -v part
sudo zpool create \
  -o ashift=12 \
  -O compression=zstd \
  -O atime=off \
  -O xattr=sa \
  -O dnodesize=auto \
  -O normalization=formD \
  -O mountpoint=none \
  tank raidz /dev/sda /dev/sdb /dev/sdc /dev/sdd

# 1c. Create datasets
sudo zfs create -o mountpoint=/tank/media/anime    tank/media/anime
sudo zfs create -o mountpoint=/tank/media/music    tank/media/music
sudo zfs create -o mountpoint=/tank/media/videos   tank/media/videos
sudo zfs create -o mountpoint=/tank/nextcloud      tank/nextcloud      # nextcloud data dir
sudo zfs create -o mountpoint=/tank/matrix/media   tank/matrix/media   # synapse media_store_path
sudo zfs set    quota=512G                         tank/matrix/media   # the funny
sudo zfs create -o mountpoint=/tank/nas            tank/nas            # smb shares root
sudo zfs create -o mountpoint=/tank/nas/kuroma     tank/nas/kuroma
sudo zfs create -o mountpoint=/tank/nas/public     tank/nas/public
sudo zfs create -o mountpoint=/tank/backups        tank/backups        # rsync /var/lib target (later)

# 1d. Get hostId before nixos-install
head -c8 /etc/machine-id
# → paste into hosts/metatron/configuration.nix networking.hostId

# 1e. Generate hardware config
nixos-generate-config --show-hardware-config
# → paste into hosts/metatron/hardware-configuration.nix

# ============================================================
# PHASE 2: NIXOS INSTALL
# ============================================================

sudo nixos-install --flake ~/System/nixos-configs#metatron --no-root-password

# Post-reboot:
# - get resume_offset: sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
# - tailscale up --auth-key=...
# - add metatron SSH host key to .sops.yaml, re-encrypt secrets

# ============================================================
# PHASE 3: SERVICES  (write server/*.nix, import in configuration.nix)
# ============================================================

# Order matters for dependencies:
# 1. postgresql          (matrix + nextcloud both need it)
# 2. adguardhome         (DNS, no deps)
# 3. matrix-synapse      (needs postgresql)
# 4. nextcloud           (needs postgresql)
# 5. jellyfin            (no deps, point at /tank/media)
# 6. navidrome           (no deps, point at /tank/media/music)
# 7. filebrowser         (no deps, point at /tank)
# 8. searxng             (no deps)
# 9. privatebin          (no deps)
# 10. stirling-pdf       (no deps)
# 11. netdata            (monitoring, no deps)
# 12. homepage           (launchpad, needs other services up for widgets)

# ============================================================
# PHASE 4: ROUTING
# ============================================================

# 4a. Create Cloudflare tunnel in dash → get token → stuff in sops
# 4b. Write server/cloudflared.nix pointing tunnel routes at caddy
# 4c. Write server/caddy.nix with virtualHosts per service
# 4d. AdGuard: point tailscale DNS at metatron tailscale IP (port 53)
#     Tailscale admin → DNS → custom nameserver → <metatron-tailscale-ip>

# ============================================================
# PASSWORDS TO GENERATE + STUFF INTO SOPS
# ============================================================
# nix-shell -p sops --run 'sops secrets/secrets.yaml'
#
# Generate each value with the command shown, paste into sops.
#
# matrix/registration-secret:
#   openssl rand -base64 48
#
# matrix/macaroon-secret:
#   openssl rand -base64 48
#
# matrix/form-secret:
#   openssl rand -base64 48
#
# matrix/db-password:
#   openssl rand -base64 32
#
# nextcloud/admin-password:
#   openssl rand -base64 24   (readable, you'll type this to log in)
#
# nextcloud/db-password:
#   openssl rand -base64 32
#
# searxng/secret-key:
#   openssl rand -hex 32
#
# adguard/password-hash:
#   nix-shell -p apacheHttpd --run 'htpasswd -bnBC 10 "" yourpassword | tr -d ":\n"'
#   (store the HASH in sops, not the plaintext)
#
# cloudflared/token:
#   *** GET FROM CLOUDFLARE DASHBOARD — cannot pregenerate ***
#   Cloudflare Zero Trust → Tunnels → Create tunnel → copy token
#
# NOT needed in sops (web UI setup on first run):
#   jellyfin, navidrome, filebrowser, privatebin, stirling-pdf, netdata, homepage
