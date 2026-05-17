# CLAUDE.md

## Repository layout

- `flake.nix` — `nixosConfigurations` + `machines` attrset (per-host `kernelPackages`, `fonts`, `displays`, `nvenc`, `hwdec`). Passed to HM as `machineConfig` via `hmExtraArgs`. Host-specific HM inlined here.
- `modules/` — NixOS modules, no aggregator — hosts import by path.
- `hosts/<name>/` — `configuration.nix`, `disko.nix`, `hardware-configuration.nix`, `fstab.nix`.
- `home/` — shared HM modules. `kuroma.nix` is the desktop entry point (imports + identity + noctalia/GUI extras). `kuroma-server.nix` is the minimal entry point (fonts, git, nushell, nvim, qt, starship, zsh only — used by metatron). All `.source` refs in `kuroma.nix`.
- `config/` — static config files, deployed via `.source` in `home/kuroma.nix`.

**Hosts:**
- `zaphkiel` — x86_64, desktop, NVIDIA RTX, nixpkgs-unstable
- `raziel` — x86_64, Framework 13 AMD AI 300, nixpkgs-unstable
- `metatron` — x86_64, home server/desktop, r5 8500G + GTX 1650, **nixpkgs-stable (25.05)**

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
r5 8500G + GTX 1650 (headless). KDE Plasma 6 + SDDM Wayland (`modules/kde.nix`). Data pool: ZFS RAIDZ1 on sda–sdd (`boot.zfs.extraPools = [ "tank" ]`). vscodium-server enabled (`modules/codiumserver.nix`). Extra users (NAS/SMB) are `isSystemUser = true` with no shell — UIDs for ACL only.

**HM on metatron:** imports `kuroma-server.nix` (fonts, git, nushell, nvim, qt, starship, zsh). `home.stateVersion = "25.11"`. No noctalia, no GUI apps, no fcitx5, no niri — KDE handles media/file apps via Plasma. `qt.nix` sets kdeglobals so KDE picks up the correct fonts. `modules/apps.nix` is NOT imported (carries millennium/Steam overlay).

**Post-install TODOs:** fill `networking.hostId` (`head -c8 /etc/machine-id`), `resume_offset` (btrfs map-swapfile), paste `nixos-generate-config` output into `hardware-configuration.nix`, create ZFS pool, register SSH host key in `.sops.yaml`.

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
SSH port 22 on `tailscale0` only. Syncthing: TCP/UDP 22000 + UDP 21027 globally. zaphkiel extras: TCP 3000 global; 11434+11435 on tailscale0.

### Syncthing (`modules/services.nix`)
Declarative. Devices: raziel + zaphkiel. Folders: Documents, PrismInstances, Wallpapers. GUI password set via `ExecStartPost` polling health endpoint then PATCHing `/rest/config/gui` with sops secret. Index reset: delete `~/.config/syncthing/index-v2/` on stale machine only.

### Backups (zaphkiel, `hosts/zaphkiel/backup.nix`)
Three rsync systemd timers every 6h (staggered 1h): home→NAS, songs→NAS, anime→NAS. `Persistent = true`.

### Users / Auth / Secrets
`users.mutableUsers = false`. Passwords: `mkpasswd --method=yescrypt`. SSH key-only. Sops: `nix-shell -p sops --run 'sops secrets/secrets.yaml'`. New host: add SSH host key to `.sops.yaml` after first boot.

### Misc gotchas
- **Noctalia single-launch** (Steam, OnlyOffice): `startupNotify = false` in `xdg.desktopEntries` override.
- **Dolphin "Open With" empty:** `kbuildsycoca6` oneshot service in `home/xdg.nix` must run at session start.
- **Blueman applet** (zaphkiel): HM adds second `ExecStart` — fix with `lib.mkForce [ "" "...blueman-applet" ]` in flake.nix.
- **zaphkiel AI services** (`hosts/zaphkiel/ai-services.nix`): llama-router :11434, llama-embedding :11435, n8n :5678, neo4j :7474/:7687, cockpit :9090. `llama` system user. Neo4j: `http.enable = true; https.enable = false`. Cockpit needs `AllowUnencrypted`, `Origins = mkForce`, `security.pam.services.cockpit = {}`.
- **Hibernate resume:** `boot.resumeDevice = "/dev/mapper/cryptroot"`, `resume_offset` from btrfs map-swapfile. NVIDIA: needs `powerManagement.enable = true` + `NVreg_PreserveVideoMemoryAllocations=1`.
- **MPV:** `hwdec` from `machineConfig` (nvdec-copy/vaapi). `nvdec` (zero-copy) fails on NixOS — use `nvdec-copy`. `osc = "no"` (thumbnail scripts replace OSC). Thumbnail server script patched for mpv 0.38+ (`--o=path` not `--o path`).
- **IMV config:** bind exec must not contain `<` (imv parses it as key-sequence). Use `pkgs.writeShellScript`.
- **Zathura:** noctaliarc fallback activation in `kuroma.nix` creates empty placeholder so zathura doesn't fail before noctalia runs.
- **code-launcher:** `nohup codium ... &` not `systemd-run --user` (misses WAYLAND_DISPLAY).
- **Gnome Keyring:** `security.pam.services.greetd.enableGnomeKeyring = true`. If stuck: delete `~/.local/share/keyrings/`.
- **State versions:** all hosts `stateVersion = "25.11"`. Do not bump.
