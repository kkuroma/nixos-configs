# CLAUDE.md

## Repository layout

- `flake.nix` — `nixosConfigurations` + `machines` attrset (per-host `kernelPackages`, `fonts`, `displays`, `nvenc`, `hwdec`). Passed to HM as `machineConfig` via `hmExtraArgs`. Host-specific HM inlined here.
- `modules/` — NixOS modules, no aggregator — hosts import by path.
- `hosts/<name>/` — `configuration.nix`, `disko.nix`, `hardware-configuration.nix`, `fstab.nix`.
- `home/` — shared HM modules. `kuroma.nix` is the desktop entry point (imports + identity + noctalia/GUI extras). `kuroma-server.nix` is the minimal entry point (git, nushell, zsh only — used by metatron). All `.source` refs in `kuroma.nix`.
- `config/` — static config files, deployed via `.source` in `home/kuroma.nix`.
- `services/` — one file per service, imported selectively per host. No aggregator. Each service file owns its Caddy vhosts (internal + public) using `config.networking.hostName`. Also contains `llama-router/` source tree.
- `hosts/metatron/` — also contains `datasets.nix` (ZFS dataset management) and `smb.nix` (Samba) since ZFS/NAS is metatron-only.

**Hosts:**
- `zaphkiel` — x86_64, desktop, NVIDIA RTX, nixpkgs-unstable
- `raziel` — x86_64, Framework 13 AMD AI 300, nixpkgs-unstable
- `metatron` — x86_64, home server/desktop, r5 8500G + GTX 1650, **nixpkgs-stable (25.11)**

**Inputs:** nixpkgs-unstable, nixpkgs-stable, disko, home-manager, home-manager-stable, noctalia, nix-vscode-extensions, nixvim, sops-nix, nixos-hardware, millennium, vscodium-server.

## Decision rules

- Host-agnostic system → `modules/`, imported per-host
- Host-specific system → `hosts/<name>/configuration.nix`
- Shared HM → `home/`, imported via `kuroma.nix`
- Host-specific HM → inline in `flake.nix` `users.${username}` (no separate `home.nix`)
- Machine hardware values → `machines.<name>` in `flake.nix`, never HM options
- Niri config → KDL in `config/niri/`, added to `niriParts`; monitor layout via `rice.niri.extraConfig` inline in flake
- Static files → `config/`, `.source` in `kuroma.nix` only
- Files needing Nix interpolation → `.text` in relevant home module
- Never write NF icons or ANSI escapes in Nix strings — use `.source` files

## Common commands

```
sudo nixos-rebuild switch --flake ~/System/nixos-configs#zaphkiel
sudo nixos-rebuild switch --flake ~/System/nixos-configs#raziel
sudo nixos-rebuild switch --flake ~/System/nixos-configs#metatron
nix flake check && nix flake update
```

After rebuild: logout+login for env/session changes; reboot for kernel/GPU/initrd/LUKS.

## Architecture

### Disk / Boot
GPT + 1G ESP + LUKS + Btrfs (`root`, `home`, `nix`, `persist`, `swap`). systemd-boot, `configurationLimit = 10`.

**Swapfiles:** zaphkiel 88G (62G RAM + 24G VRAM hibernate), raziel/metatron 40G. After creation or resize: `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile` → update `resume_offset`. Fresh install: `chattr +C` + `fallocate` (not `truncate`) to avoid btrfs CoW holes.

### GPU
- **`modules/nvidia.nix`** (zaphkiel): `open = true`, `cudaSupport = true`, nvidia-container-toolkit. `powerManagement.enable = true` + `NVreg_PreserveVideoMemoryAllocations=1` required for display restoration after hibernate (without it: DRM flip timeout on resume).
- **`modules/amd.nix`** (raziel + metatron): `hardware.graphics`, `amd_pstate=active`, `ryzenadj`, `lact`.
- **`modules/nvidia-compute.nix`** (metatron): GTX 1650 as headless CUDA. `modesetting.enable = false` — AMD iGPU owns KMS/display, NVIDIA exposes `/dev/nvidia*` for CUDA only. `open = false` (Turing TU117).

### metatron-specific (`hosts/metatron/`)
r5 8500G + GTX 1650 (headless). KDE Plasma 6 + SDDM Wayland (`modules/kde.nix`). Data pool: ZFS RAIDZ1 on 4× WD Red 12TB (sda–sdd), `boot.zfs.extraPools = [ "tank" ]`. vscodium-server enabled (`modules/codiumserver.nix`). No LUKS — boots automatically (btrfs directly on partition).

**HM on metatron:** imports `kuroma-server.nix` (git, nushell, zsh). `home.stateVersion = "25.11"`. No noctalia, no GUI apps, no fcitx5, no niri, no nixvim — KDE handles everything via Plasma. `modules/apps.nix` is NOT imported (carries millennium/Steam overlay).

**ZFS pool (`tank`):**
- Created with: `zpool create -f -o ashift=12 -O compression=zstd -O atime=off -O xattr=sa -O dnodesize=auto -O normalization=formD -O mountpoint=none tank raidz /dev/disk/by-id/...`
- Datasets managed declaratively via `hosts/metatron/datasets.nix` — systemd oneshot `zfs-datasets.service` creates, sets quota/reservation, and chmods each dataset on every boot.
- Dataset ownership: `media` group (kuroma + jellyfin + navidrome) gets read access to `/tank/media/*`. NAS personal dirs: ct/pt own their dir (770), family group covers public (775). Service dirs owned by their respective system users.
- `chown` in dataset script uses `|| true` — datasets for not-yet-enabled services don't fail; ownership applied on next rebuild once service is enabled. **Gotcha:** if a service's system user doesn't exist yet when `zfs-datasets.service` first runs, the chown silently fails and the mountpoint stays root-owned. Fix: restart `zfs-datasets.service` after the rebuild that enables the service, then restart the service.

**NAS / SMB (`hosts/metatron/smb.nix`):**
- Samba binds to `lo tailscale0` only (`bind interfaces only = yes`), nmbd disabled (`disable netbios = yes`), wsdd for discovery.
- Shares: `anime`, `music` (kuroma rw), `kuroma`, `ct`, `pt` (personal), `public` (family group), `backups` (kuroma only).
- Passwords stored in sops as `samba/{kuroma,ct,pt}`, set via `samba-passwords` systemd oneshot using `smbpasswd`.
- SMB users: `ct` (uid 1001), `pt` (uid 1002) — `isSystemUser = true`, group `family`, no shell.

**Services (`services/`):**

`modules/caddy.nix` — shared base (enable + tailscale0 firewall ports). Imported by metatron, zaphkiel, raziel. Each service file adds its own vhosts via `config.networking.hostName` — no central vhost registry.

| File | Service | Port | Hosts | Access |
|------|---------|------|-------|--------|
| `adguardhome.nix` | AdGuard Home | DNS :53, web :3000 | metatron | internal only |
| `jellyfin.nix` | Jellyfin | :8096 | metatron | internal only |
| `navidrome.nix` | Navidrome | :4533 | metatron | internal only |
| `searxng.nix` | SearXNG | :8888 | metatron | public + internal |
| `privatebin.nix` | PrivateBin | :8082 (nginx) | metatron | public + internal |
| `stirling-pdf.nix` | Stirling PDF | :8085 | metatron | public + internal |
| `nextcloud.nix` | Nextcloud | :8081 (nginx) | metatron | public + internal |
| `matrix.nix` | Matrix Synapse | :8448 | metatron | internal + public (isomorphic.to) |
| `postgresql.nix` | PostgreSQL | — | metatron | shared base (`enable = true` only) |
| `vaultwarden.nix` | Vaultwarden | :8222 | metatron | public + internal |
| `filebrowser.nix` | FileBrowser (multi-instance) | :8200+ | metatron | public + internal |
| `cloudflared.nix` | Cloudflare Tunnel | — | metatron | public ingress |
| `syncthing.nix` | Syncthing | :8384 | zaphkiel, raziel | internal only |
| `cockpit.nix` | Cockpit | :9090 | zaphkiel, raziel | internal only |
| `n8n.nix` | n8n | :5678 | zaphkiel | internal only |
| `neo4j.nix` | Neo4j | :7474 (http), :7687 (bolt) | zaphkiel | internal only |
| `llama.nix` | LLaMA router + embedding | :11434/:11435 | zaphkiel | tailscale (direct, no caddy) |

**Service access model:**
- Internal: `https://<service>.<hostname>` — AdGuard resolves `*.metatron/*.zaphkiel/*.raziel` to each host's tailscale IP. Caddy routes by Host header with `tls internal` (local CA). Requires setting tailnet DNS to AdGuard in Tailscale admin console.
- Public (kuroma.dev): `searx/pdf/pastebin/cloud/ct-dump.kuroma.dev` via cloudflared → localhost:80 → Caddy on metatron.
- Matrix: `matrix.isomorphic.to` — active. Caddy handles `.well-known/matrix/*` and proxies to :8448.
- AdGuard DNS rewrites: `*.metatron → 100.107.220.115`, `*.zaphkiel → 100.91.235.104`, `*.raziel → 100.79.72.120`.
- AdGuard password: sops `adguard/password` (plain text), bcrypt-hashed at service start via `mkpasswd` + `yq` in `preStart = lib.mkAfter`.
- SearXNG secret: sops template `searx-env` injects `SEARX_SECRET_KEY` via envsubst.

**PostgreSQL (`postgresql.nix` + per-service):**
- `postgresql.nix` is just `services.postgresql.enable = true` — the shared base. Also sets `dataDir = "/tank/services/postgresql"` (dataset: `tank/services/postgresql`, recordsize=8k).
- Each service manages its own DB setup in its own file. Nextcloud uses `database.createLocally = true`. Matrix uses `ensureUsers` + `systemd.services.postgresql-setup.postStart = lib.mkAfter` to create with `LC_COLLATE='C'` (required by Synapse; `ensureDatabases` doesn't support collation). Future services follow the same per-file pattern.
- **NixOS 25.11 postgresql-setup.service:** `ensureUsers` and `ensureDatabases` moved out of `postgresql.service`'s `postStart` into a separate `postgresql-setup.service` that runs after the main service. Any custom SQL that references roles must go in `systemd.services.postgresql-setup.postStart = lib.mkAfter`, NOT `systemd.services.postgresql.postStart`. Services that need DB users to exist (nextcloud-setup, matrix-synapse) must declare `after = [ "postgresql-setup.service" ]`.
- **Matrix DB gotcha:** `ensureDBOwnership = true` requires a matching `ensureDatabases` entry — NixOS assertion fails if used without it. Omit `ensureDBOwnership` and set `WITH OWNER=` in the `CREATE DATABASE` SQL instead.
- **dataDir migration gotcha:** Changing `dataDir` initializes a fresh empty cluster at the new path — old data is NOT migrated automatically. Old default path is `/var/lib/postgresql/<version>/` (e.g. `/var/lib/postgresql/17/`). Copy old data with rsync if needed, or delete it once confirmed empty. All per-service DB state (users, databases, tables) must be recreated from scratch on a fresh cluster.

**FileBrowser (`filebrowser.nix`):**
- Multi-instance module — add entries to the `instances` attrset at the top of the file. Each entry generates: a systemd service, a `<name>.metatron` Caddy vhost (tls internal), and a `http://<name>.kuroma.dev` Caddy vhost (public via cloudflared). Also add the hostname to `cloudflared.nix` and create sops secrets `filebrowser/<name>/username` + `filebrowser/<name>/password`.
- Ports start at :8200, increment by 1 per instance.
- Each instance runs as its directory's owner (`user`/`group` in the attrset) so there's no ownership conflict with the served root.
- Init: `ExecStartPre` runs `filebrowser config init`, `config set -r <root>`, `users add` from sops, then removes the default `admin` user (unless the sops username is `admin`). Only runs on first start (guards on DB file existence).
- DB stored in `/var/lib/filebrowser-<name>/database.db` (systemd `StateDirectory`, owned by the instance user).
- **Caddy split:** single-instance services (jellyfin, navidrome, etc.) have their vhosts in `caddy.nix`. Multi-instance modules (filebrowser) own their Caddy config internally via `mapAttrs'` — keeps port in one place and avoids drift.

**Current FileBrowser instances:**

| Name | Port | Root | User | Internal | Public |
|------|------|------|------|----------|--------|
| `ct-dump` | :8200 | `/tank/nas/ct/dump` | `ct` | `ct-dump.metatron` | `ct-dump.kuroma.dev` |

**Cloudflare tunnel routing** (set in Cloudflare dashboard OR via local `tunnelConfig` in `cloudflared.nix`):
- `searx.kuroma.dev` → `http://localhost:80`
- `pdf.kuroma.dev` → `http://localhost:80`
- `pastebin.kuroma.dev` → `http://localhost:80`
- `cloud.kuroma.dev` → `http://localhost:80`
- `ct-dump.kuroma.dev` → `http://localhost:80`
- `vault.kuroma.dev` → `http://localhost:80`

**Domains:** `kuroma.dev` (services), `isomorphic.to` (Matrix only).

**Autofs on zaphkiel/raziel (`modules/autofs.nix`):**
- Mounts: `anime`, `music`, `kuroma` from metatron (100.107.220.115) via CIFS.
- Credentials via sops template `nas-creds` generated from `samba/kuroma`.
- Backup timers (zaphkiel): home → `/mnt/NAS/kuroma/home/`, songs → `/mnt/NAS/music/`, anime → `/mnt/NAS/anime/`.
- For initial large data transfer (anime/songs), use SSH rsync directly — much faster than SMB.

### raziel-specific (`hosts/raziel/laptop.nix`)
Fingerprint: libfprint 1.94+ native for Goodix 27c6:609c — do NOT add `libfprint-2-tod1-goodix` (corrupts enrollment). After first boot: `fprintd-enroll $USER`. If fails after suspend: `systemctl restart fprintd`.

Lock before sleep (inlined in flake.nix raziel HM): `services.swayidle` with `-w` flag + `before-sleep = "noctalia-shell ipc --any-display call lockScreen lock"`. Logind: `HandlePowerKey/LidSwitch = "suspend-then-hibernate"`. Charge limit udev rule on `ucsi-source-psy-USBC000:00[14]` — left port 80%, right port 100%.

### Desktop session — niri (`modules/niri.nix`, zaphkiel + raziel)
greetd + tuigreet → `niri-session`, autologins `kuroma`. xwayland-satellite as `systemd.user.services` (Type=notify), `After = graphical-session.target` (NOT pre — races WAYLAND_DISPLAY). Use `nohup ... &` not `systemd-run --user` for Wayland apps. Niri config: inline cursor/input/window-rules → `niriParts` → `rice.niri.extraConfig` (monitor output blocks).

**Niri gotchas:** one global `layout {}` (noctalia owns it); KDL blocks need semicolons; `default-floating-position` values: `top-left/right bottom-left/right top/bottom/left/right`; no `is-only-window` in 26.04 — use `open-maximized true`; `ghostty.float` class → `app-id="ghostty[.]float"` in match.

### Noctalia theming
Writes at runtime: `niri/noctalia.kdl`, `ghostty/config.ghostty`, `nvim/lua/matugen.lua`, `~/.cache/noctalia/starship-palette.toml`.

- **Starship:** `home/starship.nix` uses sentinel activation — writes `palette = "noctalia"` + base config only. Do NOT pre-populate `[palettes.noctalia]` (noctalia appends it; pre-populating causes duplicate TOML key on theme change). Do NOT use `programs.starship` (HM symlinks it read-only). PUA codepoints via `builtins.fromJSON ''"\\uE0B6"''`.
- **VSCodium:** noctalia extension as writable copy via `home.activation` — NOT in extensions list (HM would symlink it read-only).
- **GTK:** NOT managed by HM `gtk` module (`.gtk.css.backup` conflicts). Uses `adw-gtk3` + dconf in `home/qt.nix`.
- **qt5ct/qt6ct:** only `.conf` files are HM symlinks; `colors/` subdirs are plain (noctalia writes there).

### Fonts (`home/fonts.nix`)
Options: `rice.fonts.{ui,mono,uiSize,monoSize,ghosttyFontSize}`. UI=Google Sans Flex, Mono=Maple Mono NF CN. Do NOT use `fonts.fontconfig.localConf` (broken XML in some nixpkgs versions).

**Maple Mono NF CN weight gotcha:** non-standard weights register as separate fc families (`Maple Mono NF CN ExtraLight`), not as weight variants. Requesting weight 200 of the base family silently falls back to Regular.

**ONLYOFFICE fonts:** ignores symlinks — `home.activation.onlyofficeFonts` copies real files to `~/.local/share/fonts/onlyoffice/`. Sentinel files per-package; cache (`fonts.log`, `font_selection.bin`) deleted on copy to force rescan. Find pattern must include `*.ttc` for CJK.

### Home-manager modules

| File | Contents |
|------|----------|
| `home/fonts.nix` | `rice.fonts` options, fontconfig, ONLYOFFICE font activation |
| `home/ghostty.nix` | `programs.ghostty` with `rice.fonts.mono` |
| `home/konsole.nix` | Konsole profile via `xdg.dataFile` + `kwriteconfig6` activation |
| `home/niri.nix` | Niri config assembly; `rice.niri.extraConfig` option; polkit-gnome service |
| `home/nvim.nix` | nixvim — base16, LSPs, neo-tree, treesitter, telescope, oil, lualine, conform |
| `home/apps.nix` | Packages, mpv/yazi/zathura/fzf/direnv, `code-launcher`, `init-shell` |
| `home/zsh.nix` | Zsh config, aliases, zoxide |
| `home/nushell.nix` | Nushell config, same aliases (`^` prefix on externals) |
| `home/starship.nix` | Blob-style prompt, noctalia palette sentinel |
| `home/qt.nix` | kdeglobals, qt5ct, qt6ct (`.text`), GTK dconf |
| `home/codium.nix` | VSCodium + extensions (add to both `extensions` list AND `extList`) |
| `home/fcitx5.nix` | fcitx5 JP/ZH/TH, session service, sentinel profile |
| `home/xdg.nix` | MIME defaults, kbuildsycoca6 service, Dolphin service menus (reimage/compress/ocr) |
| `home/git.nix` | git + gh (`git_protocol = "ssh"` prevents gh rewriting remotes to HTTPS) |
| `home/kuroma.nix` | Entry point: imports, identity, static `.source` files, mpv scripts, imv config |

### Shell
Zsh uses `lib.mkOrder 550` for pre-compinit in `programs.zsh.initContent`. `reload = "exec zsh"` (not `source`). Starship skipped on TTY (`TERM=linux`). PUA codepoints in starship.nix via `builtins.fromJSON ''"\\uXXXX"''`.

**`init-shell`** — generates `flake.nix` + `.envrc` for Nix devShells. `.envrc` is ALWAYS only `use flake` (any extra export causes infinite direnv reload loop). `exec zsh` in shellHook must be guarded by `[[ $- == *i* ]]` (non-interactive bootstrap would hijack shell and loop). Venv bootstrapped in init-shell, not shellHook. `direnv allow` called before `nix develop` bootstrap.

**direnv infinite loop symptoms:** `nix-direnv: Using cached dev shell` repeating. Causes: unguarded `exec zsh` in shellHook, or any `export`/`PATH_add` in `.envrc` after `use flake`.

### Networking (`modules/networking.nix`)
SSH port 22 on `tailscale0` only. Syncthing: TCP/UDP 22000 + UDP 21027 globally. zaphkiel extras: 11434+11435 on tailscale0 (llama API + embedding); n8n/neo4j-http go through Caddy. neo4j bolt :7687 open on tailscale0.

### Syncthing (`services/syncthing.nix`)
Declarative. Devices: raziel + zaphkiel. Folders: Documents, PrismInstances, Wallpapers. GUI password set via `ExecStartPost` polling health endpoint then PATCHing `/rest/config/gui` with sops secret. Index reset: delete `~/.config/syncthing/index-v2/` on stale machine only. Accessible at `syncthing.<hostname>` via Caddy.

### Backups (zaphkiel, `hosts/zaphkiel/backup.nix`)
Three rsync systemd timers every 6h (staggered 1h): home→NAS, songs→NAS, anime→NAS. `Persistent = true`.

**metatron home backup: NOT configured.** metatron's `/home` is on btrfs but has no snapper policy and no rsync to tank. The obvious target would be `tank/nas/kuroma` (RAIDZ1, already exists). TODO: add either snapper snapshots, an rsync timer to tank, or both.

### Users / Auth / Secrets
`users.mutableUsers = false`. Passwords: `mkpasswd --method=yescrypt`. SSH key-only. Sops: `nix-shell -p sops --run 'sops secrets/secrets.yaml'`. New host: add SSH host key to `.sops.yaml` after first boot.

### Misc gotchas
- **Noctalia single-launch** (Steam, OnlyOffice): `startupNotify = false` in `xdg.desktopEntries` override.
- **Dolphin "Open With" empty:** `kbuildsycoca6` oneshot service in `home/xdg.nix` must run at session start.
- **Blueman applet** (zaphkiel): HM adds second `ExecStart` — fix with `lib.mkForce [ "" "...blueman-applet" ]` in flake.nix.
- **zaphkiel AI services** (`hosts/zaphkiel/ai-services.nix`): llama-router :11434, llama-embedding :11435, n8n :5678, neo4j :7474/:7687, cockpit :9090. `llama` system user. Neo4j: `http.enable = true; https.enable = false`. Cockpit needs `AllowUnencrypted`, `Origins = mkForce`, `security.pam.services.cockpit = {}`.
- **Hibernate resume:** zaphkiel/raziel: `boot.resumeDevice = "/dev/mapper/cryptroot"`. metatron (no LUKS): `boot.resumeDevice = "/dev/nvme0n1p2"`. All: `resume_offset` from `btrfs inspect-internal map-swapfile -r /swap/swapfile`. NVIDIA: needs `powerManagement.enable = true` + `NVreg_PreserveVideoMemoryAllocations=1`.
- **MPV:** `hwdec` from `machineConfig` (nvdec-copy/vaapi). `nvdec` (zero-copy) fails on NixOS — use `nvdec-copy`. `osc = "no"` (thumbnail scripts replace OSC). Thumbnail server script patched for mpv 0.38+ (`--o=path` not `--o path`).
- **IMV config:** bind exec must not contain `<` (imv parses it as key-sequence). Use `pkgs.writeShellScript`.
- **Zathura:** noctaliarc fallback activation in `kuroma.nix` creates empty placeholder so zathura doesn't fail before noctalia runs.
- **code-launcher:** `nohup codium ... &` not `systemd-run --user` (misses WAYLAND_DISPLAY).
- **Gnome Keyring:** `security.pam.services.greetd.enableGnomeKeyring = true`. If stuck: delete `~/.local/share/keyrings/`.
- **State versions:** all hosts `stateVersion = "25.11"`. Do not bump.
- **Vaultwarden `ProtectSystem=strict`:** The NixOS vaultwarden module sets `ProtectSystem=strict`, making the whole filesystem read-only except `StateDirectory` (`/var/lib/vaultwarden`). If `DATA_FOLDER` is outside that (e.g. `/tank/services/vaultwarden`), add `systemd.services.vaultwarden.serviceConfig.ReadWritePaths = [ "/tank/services/vaultwarden" ]` or vaultwarden exits with EROFS (errno 30) on startup.
- **Nextcloud fresh install recovery:** If `nextcloud-setup` fails mid-install (e.g. race condition against `postgresql-setup.service`), it leaves partial state. To retry cleanly: drop and recreate the `nextcloud` DB (`sudo -u postgres psql -c 'DROP DATABASE "nextcloud";'` + `CREATE DATABASE "nextcloud" OWNER nextcloud;`), then delete both `config.php` and the `data/` dir (`sudo rm -rf /tank/services/nextcloud/data /tank/services/nextcloud/config/config.php`). The error `Login is invalid because files already exist for this user` means `data/admin/` exists from a prior failed run — clear `data/` entirely.
