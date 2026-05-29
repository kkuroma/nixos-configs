# CLAUDE.md

## Repository layout

- `flake.nix` — `nixosConfigurations` + `machines` attrset (per-host `kernelPackages`, `fonts`, `displays`, `nvenc`, `hwdec`). Passed to HM as `machineConfig` via `hmExtraArgs`. Host-specific HM inlined here.
- `modules/` — NixOS modules, no aggregator — hosts import by path.
- `hosts/<name>/` — `configuration.nix`, `disko.nix`, `hardware-configuration.nix`, `fstab.nix`, plus host-specific service overlays (`homepage.nix`, `datasets.nix`, etc.).
- `home/` — shared HM modules. `kuroma.nix` is the desktop entry point. `kuroma-server.nix` is the minimal entry point (git, nushell, zsh — used by metatron). All `.source` refs in `kuroma.nix`.
- `config/` — static config files, deployed via `.source` in `home/kuroma.nix`.
- `services/` — one file per service, imported selectively per host. No aggregator. Each service file owns its Caddy vhosts using `config.networking.hostName`.

**Hosts:** `zaphkiel` — desktop, NVIDIA RTX, nixpkgs-unstable | `raziel` — Framework 13 AMD, nixpkgs-unstable | `metatron` — home server, r5 8500G + GTX 1650, nixpkgs-unstable

**Inputs:** nixpkgs-unstable, disko, home-manager, noctalia, nix-vscode-extensions, nixvim, sops-nix, nixos-hardware, vscodium-server.

## Decision rules

- Host-agnostic system → `modules/`, imported per-host
- Host-specific system → `hosts/<name>/configuration.nix`
- Shared HM → `home/`, imported via `kuroma.nix`
- Host-specific HM → inline in `flake.nix` `users.${username}`
- Machine hardware values → `machines.<name>` in `flake.nix`, never HM options
- Static files → `config/`, `.source` in `kuroma.nix` only; files needing Nix interpolation → `.text` in relevant module
- Never write NF icons or ANSI escapes in Nix strings — use `.source` files

## Common commands

```
sudo nixos-rebuild switch --flake ~/System/nixos-configs#zaphkiel
sudo nixos-rebuild switch --flake ~/System/nixos-configs#metatron
nix flake check && nix flake update
```

After rebuild: logout+login for env/session changes; reboot for kernel/GPU/initrd.

## Architecture

### Disk / Boot
GPT + 1G ESP + LUKS + Btrfs (`root`, `home`, `nix`, `persist`, `swap`). systemd-boot, `configurationLimit = 10`. metatron has no LUKS — boots automatically.

**Swapfiles:** after creation or resize: `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile` → update `resume_offset`. Use `chattr +C` + `fallocate` (not `truncate`) to avoid CoW holes.

### Kernel
- `modules/boot.nix` blacklists `algif_aead` (CVE-2026-31431, unpatched in 6.12 LTS at last check).
- Per-host kernel: zaphkiel = zen, raziel = latest, metatron = LTS (latest breaks ZFS).

### GPU
- **zaphkiel** (`modules/nvidia.nix`): `open = true`, `cudaSupport = true`. `powerManagement.enable = true` + `NVreg_PreserveVideoMemoryAllocations=1` required for display after hibernate.
- **raziel + metatron** (`modules/amd.nix`): `hardware.graphics`, `amd_pstate=active`.
- **metatron** (`modules/nvidia-compute.nix`): GTX 1650 headless CUDA. `modesetting.enable = false`, `open = false` (Turing TU117).

### metatron ZFS (`tank`)
RAIDZ1 on 4× WD Red 12TB. Datasets managed via `hosts/metatron/nas/datasets.nix` — systemd oneshot `zfs-datasets.service`.

**Gotchas:**
- `zfs-datasets.service` is **first-creation only** — it tolerates `zfs create` failures (`|| true`) so re-runs are no-ops, but it does NOT update existing dataset properties idempotently. To change a quota/reservation, do it manually with `zfs set`. The service exists so a new metatron-shaped host can bootstrap cleanly.
- `chown` uses `|| true` — restart `zfs-datasets.service` then the service if ownership silently failed (service user didn't exist on first run).
- **Quota/reservation reduction:** ZFS refuses to lower quota below current reservation. Fix: `zfs set reservation=none tank/<dataset>` first, then rebuild.

### NAS / SMB
Samba binds to `lo ${metatronIP}` only. Passwords in sops as `samba/{kuroma,ct,pt}`, set via `samba-passwords` oneshot. SMB users: `ct` (uid 1001), `pt` (uid 1002).

`samba-passwords.service` refuses to run if a sops secret is empty/missing (`[ -s ${secret} ]` guard) — avoids silently zero-passwording an account if sops fails to materialize.

### Services

`modules/caddy.nix` — shared base. Each service file adds its own vhosts via `config.networking.hostName`.

| File | Service | Port | Hosts | Access |
|------|---------|------|-------|--------|
| `adguardhome.nix` | AdGuard Home | DNS :53, web :3000 | metatron | internal |
| `jellyfin.nix` | Jellyfin | :8096 | metatron | internal |
| `navidrome.nix` | Navidrome | :4533 | metatron | internal |
| `searxng.nix` | SearXNG | :8888 | metatron | public + internal |
| `privatebin.nix` | PrivateBin | :8082 | metatron | public + internal |
| `stirling-pdf.nix` | Stirling PDF | :8085 | metatron | public + internal |
| `nextcloud.nix` | Nextcloud | :8081 | metatron | public + internal |
| `matrix.nix` | Matrix Synapse | :8448 | metatron | internal + public |
| `postgresql.nix` | PostgreSQL | — | metatron, zaphkiel | shared base only |
| `vaultwarden.nix` | Vaultwarden | :8222 | metatron | public + internal |
| `filebrowser.nix` | FileBrowser (multi) | :8200+ | metatron | public + internal |
| `forgejo.nix` | Forgejo | :1412 | metatron | public + internal |
| `nut.nix` | NUT (UPS) | :3493 | metatron | localhost only |
| `syncthing.nix` | Syncthing | :8384 | zaphkiel, raziel | internal |
| `cockpit.nix` | Cockpit | :9090 | zaphkiel, raziel | internal |
| `n8n.nix` | n8n | :5678 | zaphkiel | internal |
| `arr/sonarr.nix` | Sonarr | :8989 | zaphkiel | internal |
| `arr/radarr.nix` | Radarr | :7878 | zaphkiel | internal |
| `neo4j.nix` | Neo4j | :7474/:7687 | zaphkiel | internal |
| `llama.nix` | LLaMA router + embedding | :11434 / :11435 | zaphkiel, metatron | tailscale via Caddy |
| `hosts/<name>/homepage.nix` | homepage-dashboard | :8083 | metatron, zaphkiel | internal |

**Service access model:** Internal: `https://<service>.<hostname>` via AdGuard DNS + Caddy `tls internal`. Public: cloudflared → `localhost:80` → Caddy. DNS rewrites: `*.metatron → 100.107.220.115`, `*.zaphkiel → 100.91.235.104`, `*.raziel → 100.79.72.120`.

### AdGuard (`services/adguardhome.nix`)
- `bind_hosts = [ "127.0.0.1" "${metatronIP}" ]` — explicit list, not `0.0.0.0`, so a disabled firewall doesn't expose an open resolver.
- `mutableSettings = true`. **Admin password is non-declarative** — lives in `/var/lib/AdGuardHome/AdGuardHome.yaml` under `users:`. To set/reset: stop service, edit file with a bcrypt hash (`htpasswd -bnBC 10 "" yourpassword | tr -d ':\n'`), restart.
- **Fresh-install footgun:** on a from-scratch metatron, AdGuard boots into the public setup wizard with no auth until the YAML is hand-edited. Make this the first post-rebuild step.

### LLaMA (`services/llama.nix`)
- Router on :11434, embedding server on :11435. Both `--host 127.0.0.1`; Caddy exposes them on tailscale via `llama.${host}` / `llama-emb.${host}`. Do **not** bind `0.0.0.0` — docker/libvirt bridges would reach the model with no auth.
- Active on zaphkiel (current GPU host) and metatron (GTX 1650). Models live under `/Vault/llm-models` (zaphkiel) — service has `Vault.mount` ordering.

### PostgreSQL
`postgresql.nix` is just `enable = true` + `dataDir = "/tank/services/postgresql"` (metatron) or `/Vault/postgresql` (zaphkiel). Each service manages its own DB.

**NixOS 25.11:** `ensureUsers`/`ensureDatabases` run in `postgresql-setup.service`. Custom SQL and dependent services need `after = [ "postgresql-setup.service" ]`; custom SQL in `lib.mkAfter` on `postStart`. **Matrix DB:** omit `ensureDBOwnership`, use `WITH OWNER=` in `CREATE DATABASE` SQL instead (Synapse requires `LC_COLLATE=C`).

### FileBrowser (multi-instance)
Add entries to `instances` attrset in `filebrowser.nix`. Each entry generates a hardened systemd service + internal + public Caddy vhosts. Ports start at :8200. Also add hostname to `cloudflared.nix`.

- Per-instance sops secrets: `filebrowser/<name>/username`, `filebrowser/<name>/password`.
- **Init is one-shot:** `ExecStartPre` runs only when the SQLite DB doesn't exist. Rotating the sops password does NOT update the DB. To rotate: `sudo -u <user> filebrowser users update <name> --password <new> -d /var/lib/filebrowser-<name>/database.db`.

### Homepage (`hosts/<name>/homepage.nix`)
Port :8083. Wallpaper at `hosts/<name>/homepage.png` — must `git add` before building. Palettes: metatron = Everforest dark, zaphkiel = Catppuccin Mocha.

**Critical gotchas:**
- `settings.layout` must be a **list** of single-key attrsets (not an attrset — attrsets sort alphabetically).
- Do NOT set `max-width` on `#page_wrapper` — clips backdrop-blur. Use `width: 100%`.
- Info widget DOM: resources and datetime/search/weather are in **separate flex containers** — CSS `order` does NOT work across them.
- Glances widget broken in 1.7.0 — disabled on all hosts.
- NUT "peanut" widget requires Peanut2 REST server (not in nixpkgs) — not configured.
- metatron `BindReadOnlyPaths`: list each ZFS child dataset individually.

### Forgejo (`forgejo.nix`)
Port :1412. SSH on :22 via system sshd (tailscale only). Clone URL: `forgejo@metatron:kuroma/<repo>.git`. State at `/tank/services/forgejo`. Theme: Natsumikan (custom CSS + Google Sans Flex, symlinked from Nix store via `ExecStartPre`). Icon: `services/icon.webp` → PNG via imagemagick at build time.

**Gotchas:**
- `services.forgejo.secrets` is `attrsOf (attrsOf path)` — `{ section.KEY = path; }`. Use `lib.mkForce`.
- `forgejo-secrets.service`: set `ReadWritePaths = lib.mkForce []` — it's a no-op (sops secrets never empty).
- `customDir` doesn't exist on fresh ZFS — `forgejo-init-dirs` oneshot creates it.
- `loadOAuth2From()` writes `app.ini` on startup but pre-start sets it read-only — fix: `ExecStartPre = lib.mkAfter [ "+chmod u+w .../app.ini" ]`.
- App name: `settings.DEFAULT.APP_NAME` (old `appName` option removed).
- **Actions runner:** registration token from `/-/admin/runners`, stored as `forgejo/runner-token` in sops. `tokenFile` expects `KEY=VALUE` — use `sops.templates."forgejo-runner-env"` with `TOKEN=<placeholder>`.
- **SSH user:** system user is `forgejo`, not `git`. Set `settings.server.SSH_USER = "forgejo"` or `git@` clone URLs will fail (no `git` system user exists).
- **SSH keys:** Forgejo writes registered keys to `${stateDir}/.ssh/authorized_keys`; system sshd reads it via `%h/.ssh/authorized_keys`. Keys added via web UI at `https://git.kuroma.dev/user/settings/keys`.
- **sshd hardening:** `services.openssh.extraConfig` adds a `Match User forgejo` block disabling agent/TCP/stream forwarding, PTY, X11, and tunnels. Defense-in-depth in case a key ever lands in `authorized_keys` without the standard `command="forgejo serv …"` prefix — the session is still unusable as a pivot.
- **Push mirror to GitHub:** repo Settings → Mirror Settings → Add Push Mirror → HTTPS URL + GitHub PAT (`repo` scope). Forgejo is source of truth; GitHub is mirror.

### NUT (`services/nut.nix`, metatron only)
Module namespace is `power.ups` (not `services.nut`). Hardware: generic MEC0003 UPS (vendor `0001:0000`, Megatec Q1 protocol) — driver `blazer_usb`. upsd listens on `127.0.0.1:3493`.

- **70% shutdown:** systemd timer polls `upsc` every minute; shuts down if status contains `OB` and charge < 70%.
- **Email alerts:** upsmon `NOTIFYCMD` + msmtp → smtp.zoho.com → `contact@kuroma.dev` on ONBATT/ONLINE/LOWBATT/COMMBAD/COMMOK/SHUTDOWN. Reuses `vaultwarden/smtp-password`.
- Sops: `nut/monitor-password`. `upsc` reads are unauthenticated from localhost.

### Stirling-PDF (`services/stirling-pdf.nix`)
`DynamicUser=true` plus full systemd hardening: `NoNewPrivileges`, `ProtectHome`, `ProtectKernel{Tunables,Modules,Logs}`, `ProtectControlGroups`, `ProtectClock`, `ProtectHostname`, `ProtectProc=invisible`, `LockPersonality`, `RestrictNamespaces`, `RestrictRealtime`, `RestrictSUIDSGID`, `RestrictAddressFamilies = AF_UNIX AF_INET AF_INET6`, `DevicePolicy=closed`, `PrivateDevices`.

`MemoryDenyWriteExecute` is **intentionally omitted** — the JVM JIT needs W+X. If Stirling fails to start after a rebuild, check journalctl for sandbox denials; the most likely culprit is `RestrictNamespaces` or `ProtectKernelLogs`.

### Syncthing (`services/syncthing.nix`)
`ExecStartPost` waits for the API, then PATCHes the GUI password from `sops:syncthing/password`. The JSON body is built with `jq -Rn --arg p` — passwords containing `"`/`\`/newlines are safe.

### Cloudflare tunnel
`searx/pdf/pastebin/cloud/ct-dump/vault/git.kuroma.dev` → `http://localhost:80`. Set in Cloudflare dashboard or `tunnelConfig` in `cloudflared.nix`. Domains: `kuroma.dev` (services), `isomorphic.to` (Matrix).

**Public service notes:**
- `ct-dump.kuroma.dev`: dumping ground, low-trust by design.
- `searx.kuroma.dev`: relies on Cloudflare bot protection (intentional, no in-host rate limiting).
- `pdf.kuroma.dev`: same model. Stirling is hardened (see above) but parses untrusted input — candidate for shutdown if usage is rare.

### Networking
SSH on `tailscale0` only (open via `modules/networking.nix`). Syncthing: TCP/UDP 22000 + UDP 21027 globally. zaphkiel extras: 11434+11435 on tailscale0 (Caddy reverse-proxies; llama itself listens on 127.0.0.1); neo4j bolt :7687 on tailscale0.

### Autofs / Backups (zaphkiel)
Autofs mounts `anime`, `music`, `kuroma`, `research` from metatron via CIFS. rsync timers in `hosts/zaphkiel/backup.nix` push anime (6h), movies (6h), music (6h), research (weekly), home (6h, requires `/mnt/NAS` mounted). **metatron home backup: not configured** (TODO: snapper or rsync to `tank/nas/kuroma`).

**Media layout:** `vault/media/anime` → `/mnt/Vault-Storage/media/anime` (Sonarr), `vault/media/movies` → `/mnt/Vault-Storage/media/movies` (Radarr). Mirrored on metatron as `tank/media/anime` (3T) and `tank/media/movies` (1T). Keep anime and movies in separate datasets — Sonarr manages anime/shows, Radarr manages movies; Jellyfin expects separate library roots for each type.

### raziel
Fingerprint: `libfprint` native — do NOT add `libfprint-2-tod1-goodix` (corrupts enrollment). `fprintd-enroll $USER` after first boot. `fprintAuth = true` for sudo + polkit (accepted tradeoff: laptop, physically attended).

**Charge-limit udev rule (`hosts/raziel/laptop.nix`):** picks 80% (left port) / 100% (right port). User-session calls (`noctalia-shell ipc`, `notify-send`) are wrapped in a `run_user` helper that no-ops when `/run/user/1000/bus` doesn't exist — safe during early boot / no-login.

### Desktop session — niri (zaphkiel + raziel)
greetd + tuigreet → `niri-session`. xwayland-satellite: `After = graphical-session.target` (not pre — races WAYLAND_DISPLAY). Use `nohup ... &` not `systemd-run --user`. One global `layout {}` (noctalia owns it). No `is-only-window` in 26.04 — use `open-maximized true`.

### Noctalia theming
Writes at runtime: niri KDL, ghostty config, nvim matugen.lua, starship palette.

- Starship: do NOT pre-populate `[palettes.noctalia]` (duplicate TOML key on theme change). Do NOT use `programs.starship` (read-only symlink).
- VSCodium: noctalia extension as writable copy via `home.activation` — NOT in extensions list.
- GTK: NOT managed by HM `gtk` module — uses `adw-gtk3` + dconf in `home/qt.nix`.
- **Maple Mono weight gotcha:** non-standard weights register as separate fc families, not weight variants.
- **ONLYOFFICE fonts:** ignores symlinks — copy real files via `home.activation`; include `*.ttc` for CJK.

### Shell
`reload = "exec zsh"`. `init-shell` `.envrc` must be ONLY `use flake` — any extra export causes infinite direnv reload loop. `exec zsh` in shellHook must be guarded by `[[ $- == *i* ]]`.

### Users / Auth / Secrets
- `users.mutableUsers = false`. Passwords: `mkpasswd --method=yescrypt`.
- `modules/users.nix` currently ships `hashedPassword` inline for `kuroma` and `root`. Repo is push-mirrored to public GitHub via Forgejo — these hashes are public. Acceptable only if the password is unique to this host and high-entropy; otherwise migrate to `hashedPasswordFile` from sops.
- Sops: `nix-shell -p sops --run 'sops secrets/secrets.yaml'`. New host: add SSH host key to `.sops.yaml` after first boot.
- **World-readable secrets (`mode = "0444"`):** `nut/monitor-password` (local-only impact), `forgejo/runner-token` (registration only). `cloudflared/token` and `vaultwarden/smtp-password` should ideally have proper owners — DynamicUser blocks that for cloudflared without restructuring.

## Pending work
- **Vault-Storage ext4 → btrfs migration:** plan documented in `PLAN.md`. Waiting on current arxiv rsync to metatron to finish before starting.
- **`hashedPasswordFile` migration** for kuroma/root in `modules/users.nix` (if/when convenient).

## Misc gotchas
- **Vaultwarden `ProtectSystem=strict`:** add `ReadWritePaths = [ "/tank/services/vaultwarden" ]` or exits with EROFS.
- **Hibernate resume:** zaphkiel/raziel: `resumeDevice = "/dev/mapper/cryptroot"`. metatron: `/dev/nvme0n1p2`. NVIDIA needs `powerManagement.enable + NVreg_PreserveVideoMemoryAllocations=1`.
- **MPV:** use `nvdec-copy` not `nvdec`. `osc = "no"` (thumbnail scripts replace OSC).
- **Dolphin "Open With" empty:** `kbuildsycoca6` oneshot must run at session start.
- **Nextcloud fresh install recovery:** drop+recreate DB, delete `config.php` and `data/` if `nextcloud-setup` fails mid-install.
- **State versions:** all hosts `stateVersion = "25.11"`. Do not bump.
