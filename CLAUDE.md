# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

- `flake.nix` — per-host `nixosConfigurations`. Wires inputs, `specialArgs`, home-manager, `niriParts`.
- `modules/` — topic-scoped NixOS modules. No aggregator — hosts import explicitly by path.
- `hosts/<name>/` — `configuration.nix`, `disko.nix`, `hardware-configuration.nix`, `home.nix`, `fstab.nix`.
- `home/` — shared home-manager modules. `kuroma.nix` is a pure entry point (imports + identity only). All `.source` refs live here for traceability.
- `config/` — raw static config files. Deployed via `.source` in `home/kuroma.nix`.

Hosts: `zaphkiel` (x86_64-linux, desktop, NVIDIA RTX), `raziel` (x86_64-linux, Framework 13 AMD AI 300 laptop). Inputs: nixpkgs-unstable, disko, home-manager, noctalia, nix-vscode-extensions, nixvim, sops-nix, nixos-hardware.

## Decision rules

- **Host-agnostic system** → `modules/`, import in each host's `configuration.nix`
- **Host-specific system** → `hosts/<name>/configuration.nix` or host-only module
- **Shared HM** → `home/`, import in `home/kuroma.nix`
- **Host-specific HM** → `hosts/<name>/home.nix`
- **Niri config (all hosts)** → KDL file in `config/niri/`, add to `niriParts` in `flake.nix`
- **Monitor layout** → `rice.niri.extraConfig` in `hosts/<name>/home.nix`
- **Static files (no interpolation)** → `config/`, `.source` in `kuroma.nix` only — never scatter
- **Files needing Nix interpolation** → `.text` in the relevant home module
- **Never write NF icons or ANSI escapes directly in Nix strings** — use `.source` files

## Common commands

```
sudo nixos-rebuild switch --flake ~/System/nixos-configs#zaphkiel
sudo nixos-rebuild switch --flake ~/System/nixos-configs#raziel
nix flake check
nix flake update
```

After rebuild: **logout+login** for env var / session service changes; **reboot** for kernel/amdgpu/initrd/LUKS.

## Architecture

### Disk / Boot
GPT + 1G ESP + LUKS + Btrfs (`root`, `home`, `nix`, `persist`, `swap` 88G). systemd-boot, `configurationLimit = 10`. GRUB migration: run `sudo bootctl --esp-path=/boot install` first, then rebuild.

**Swapfile (zaphkiel)**: 88G — sized for 62G RAM + 24G VRAM state saved to RAM during hibernate. disko declares size; on a fresh install the swapfile must be created with `chattr +C` + `fallocate` (not `truncate`) to avoid btrfs holes. After creation or resize: `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile` → update `resume_offset` in `hosts/zaphkiel/configuration.nix`.

### GPU
- **`modules/nvidia.nix`** (zaphkiel): `hardware.nvidia.open = true`, `cudaSupport = true`, nvidia-container-toolkit for Docker GPU passthrough. `services.lact.enable = true`. Full rebuild + reboot required on changes.
  - `hardware.nvidia.powerManagement.enable = true` — enables nvidia-suspend/hibernate/resume systemd services.
  - `boot.extraModprobeConfig = "options nvidia NVreg_PreserveVideoMemoryAllocations=1"` — required alongside powerManagement for display to restore after hibernate. Without it: DRM flip timeouts and `Failed to apply atomic modeset` on resume.
- **`modules/amd.nix`** (raziel): `hardware.graphics`, `amd_pstate=active` kernel param, `ryzenadj`, `lact`. Used with `nixos-hardware.nixosModules.framework-amd-ai-300-series` in flake.

### raziel-specific (`hosts/raziel/laptop.nix`)
Fingerprint: `fprintd` + `libfprint-2-tod1-goodix` TOD driver (Goodix 27c6:609c sensor). PAM fprint enabled for `sudo` and `polkit-1`. `fwupd` for BIOS/EC/firmware updates. `fw-ectool` for charge limit control. After first boot: `fprintd-enroll $USER`. If fingerprint fails after suspend: `systemctl restart fprintd`.

raziel display: `eDP-1`, 2880x1920@120, scale 2.0 (1440x960 logical).

### Virtualization (`modules/virtualization.nix`)
- **Docker** — GPU passthrough via nvidia-container-toolkit
- **Podman** (`dockerCompat = false`) — distrobox only; separate socket from Docker
- **Distrobox** — run as user `kuroma`, not root (root causes `no such option: pty`). Starship `[container]` module reads `/run/.containerenv` to show container name.
- **KVM/QEMU + libvirtd** — virt-manager, SPICE USB redirect, qemu-guest/spice-vdagent for clipboard in guests

### Kernel
`linuxPackages_xanmod_latest`. On zaphkiel, xanmod triggers local nvidia module compilation on update — reboot required (nvidia CDI logs "version mismatch" until then). On raziel, xanmod is fine without extra compilation.

### Desktop session (`modules/niri.nix`)
Login: greetd + tuigreet → `niri-session`, autologins `kuroma`. Packages: noctalia, xwayland-satellite, `pkgs.xrdb` (not `xorg.xrdb` — renamed), wl-clipboard, papirus, kdePackages.breeze.

Env vars: `XCURSOR_THEME=breeze_cursors`, `XCURSOR_SIZE=24`, `QT_QPA_PLATFORMTHEME=qt6ct` via `environment.variables`; `__GLX_VENDOR_LIBRARY_NAME=nvidia` in nvidia.nix; `DISPLAY=:0` via `systemd.user.sessionVariables` in `home/niri.nix`.

**xwayland-satellite**: runs as `systemd.user.services` (Type=notify, `:0`), NOT `spawn-at-startup`. Must use `After = [ "graphical-session.target" ]` — NOT `graphical-session-pre.target` (races before niri exports `WAYLAND_DISPLAY` → `NoCompositor` panic).

**WAYLAND_DISPLAY**: set at runtime by niri. Use `nohup ... &` not `systemd-run --user` when spawning Wayland apps.

### Niri config assembly (`home/niri.nix`)
1. **Inline**: cursor, input, `spawn-at-startup "noctalia-shell"`, `ghostty.float` window-rule
2. **`niriParts`**: `config/niri/noctalia.kdl` (includes noctalia runtime kdl + overrides), `config/niri/keybinds.kdl`
3. **`rice.niri.extraConfig`** in `hosts/<name>/home.nix`: monitor `output {}` blocks

zaphkiel monitors: two 1080p@120Hz. HDMI-A-1 portrait (rotate 90°), HDMI-A-2 landscape primary.

### Niri gotchas
- One global `layout {}` only — noctalia owns it. Use per-output `layout {}` for overrides.
- KDL inline blocks need semicolons: `border { width 2; }` not `border { width 2 }`
- Nix source paths cannot have spaces; `xdg.configFile` key strings can.
- `default-floating-position` valid values (26.04+): `top-left/right`, `bottom-left/right`, `top/bottom/left/right`. `output-center` removed.
- `default-floating-width/height` don't exist — use `default-column-width`/`default-window-height` in window-rules.
- Ghostty `--class` needs a dot (e.g. `ghostty.float`). Escape in niri match: `app-id="ghostty[.]float"`.
- No `is-only-window` in niri 26.04. Use global `open-maximized true` instead.

### Noctalia theming
Noctalia writes at runtime: `~/.config/niri/noctalia.kdl`, `~/.config/ghostty/config.ghostty`, `~/.config/nvim/lua/matugen.lua`, `~/.cache/noctalia/starship-palette.toml` (palette cache — `.cache` is correct, it's derived).

- **Starship**: Do NOT use `programs.starship` — HM creates a read-only symlink blocking noctalia writes. `home/starship.nix` uses a sentinel activation: when base config changes, writes `palette = "noctalia"` + base config only. Do NOT pre-populate `[palettes.noctalia]` from the cache — noctalia appends it itself, and pre-populating causes a duplicate key TOML error on theme change. PUA codepoints embedded via `builtins.fromJSON ''"\\uE0B6"''` — direct paste loses PUA chars in transit.
- **VSCodium**: Noctalia extension installed as writable copy via `home.activation.noctaliaThemeExtension` — NOT in extensions list (HM would symlink it read-only).
- **GTK**: Not managed by HM `gtk` module (causes `.gtk.css.backup` conflicts). `adw-gtk3` + dconf settings in `home/qt.nix`.
- **qt5ct/qt6ct**: Only `qt6ct.conf`/`qt5ct.conf` are HM symlinks; `colors/` subdirs are plain (noctalia writes there).

### Fonts
Options in `home/fonts.nix`: `config.rice.fonts.{ui,mono,uiSize,monoSize}`. Edit defaults in `fonts.nix` only — all modules read from there. UI=Google Sans Flex, Mono=Maple Mono NF CN. Do NOT use `fonts.fontconfig.localConf` (generates broken XML in some nixpkgs versions).

### Home-manager modules

| File | Contents |
|------|----------|
| `home/fonts.nix` | `rice.fonts` options, fontconfig, font file deployment |
| `home/ghostty.nix` | `programs.ghostty` with `rice.fonts.mono`, noctalia config-file ref |
| `home/niri.nix` | Niri config assembly; `rice.niri.extraConfig` option |
| `home/nvim.nix` | nixvim — base16, LSPs, neo-tree, treesitter, telescope, oil, lualine, conform |
| `home/apps.nix` | Packages, `programs.{yazi,btop,mpv,zathura,fzf,direnv}`, `code-launcher`, `init-shell` |
| `home/zsh.nix` | Zsh config, aliases, zoxide |
| `home/nushell.nix` | Nushell config, same aliases |
| `home/starship.nix` | Starship prompt (blob-style, noctalia palette, mutable toml sentinel) |
| `home/qt.nix` | kdeglobals, qt5ct, qt6ct (`.text`), GTK dconf — all use `rice.fonts.*` |
| `home/codium.nix` | VSCodium + extensions + settings + noctalia extension activation |
| `home/fcitx5.nix` | fcitx5 input method (JP/ZH/TH), session service, sentinel profile |
| `home/xdg.nix` | MIME defaults, kbuildsycoca6 service, Vivaldi CSS, Dolphin service menus |
| `home/git.nix` | `programs.git` — user, email, defaultBranch, pull.rebase |

### Shell (zsh + nushell)
Shared aliases in both. Nushell uses `^` prefix on external commands (`grep`, `diff`, `ip`, etc.) to bypass builtins. `reload = "exec zsh"` not `source` (avoids NVM double-init). Zsh uses `lib.mkOrder 550` in `programs.zsh.initContent` for pre-compinit content.

**Starship prompt**: `shell`(bold cyan text, zsh silent) → `container`(green blob, distrobox) → `directory`(blue) → `git_branch`(maroon) → `git_state/status/metrics` → `nix_shell`(sky, fires on `IN_NIX_SHELL`) → `DEV_SHELL`(yellow) → `$fill` → `cmd_duration`(peach, >1s) → `time`(mauve) → newline → `$character`. All segments except shell use blob-style pill caps (U+E0B6/U+E0B4).

### Dev shells (`shells/`)
- `shells/python/` — python3 + uv/ruff/black/pyright/jupyter. shellHook: `export DEV_SHELL=python; exec zsh`
- `shells/networking/` — pentest toolkit. shellHook: `export DEV_SHELL=networking; exec zsh`

`exec zsh` replaces the nix develop bash process with zsh. `DEV_SHELL` is preserved because it's exported before exec.

**`init-shell`** (in `home/apps.nix`): generates `flake.nix` + `.envrc` for per-project shells. Flags: `--python`, `--npx`, `--networking`, `--cuda`. Writes `use flake` + runs `direnv allow`. `--python`/`--cuda` shellHooks auto-create `.venv` with `uv venv`.

**direnv**: `programs.direnv.enable = true; nix-direnv.enable = true` in `home/apps.nix`.

### Users / Auth
`users.mutableUsers = false`. Passwords as `hashedPassword` (yescrypt). Update: `mkpasswd --method=yescrypt`, paste hash, rebuild. SSH key-only (`PasswordAuthentication = false`, `PermitRootLogin = "no"`).

### Secrets (sops-nix)
NAS credentials in `secrets/secrets.yaml`. Edit: `nix-shell -p sops --run 'sops secrets/secrets.yaml'`. Age keys in `.sops.yaml`: host key from `/etc/ssh/ssh_host_ed25519_key`, personal key at `~/.config/sops/age/keys.txt`. New host: add to sops after first boot, then add `modules/sops.nix` import.

### Neovim (`home/nvim.nix`)
nixvim. Do NOT also enable `programs.neovim` (conflict). LSPs: nil_ls, pyright, lua_ls, rust_analyzer, ts_ls, bashls, texlab, taplo, yamlls. Formatters (conform, on save): nixfmt, black, stylua, prettier — binaries in `apps.nix`. Key bindings: `<leader>e` neo-tree, `<leader>o` oil, `<leader>ff/fg/fb/fh` telescope, `gd/gr/K/<leader>ca/<leader>rn` LSP.

### VSCodium (`home/codium.nix`)
Use `programs.vscodium` not `programs.vscode` (vscode targets wrong extensions dir). Extensions from nix-vscode-extensions open-vsx. **Adding an extension: add to both `profiles.default.extensions` AND `extList` in the `let` block.** `latex-workshop` patched to remove engine version constraint.

### Misc gotchas
- **Noctalia single-launch bug** (Steam, OnlyOffice): apps that don't call `gdk_notify_startup_complete()` block re-launch from noctalia. Fix: `xdg.desktopEntries` override with `startupNotify = false` in `home/xdg.nix`.
- **Dolphin "Open With" empty**: `systemd.user.services.kbuildsycoca6` oneshot (in `home/xdg.nix`) must run at session start.
- **code-launcher**: launched via `ghostty --class=ghostty.float`. Uses `nohup codium ... &` not `systemd-run --user` (systemd-run misses `WAYLAND_DISPLAY`).
- **Gnome Keyring**: `security.pam.services.greetd.enableGnomeKeyring = true` auto-unlocks at login. If stuck, delete `~/.local/share/keyrings/` and re-login.
- **Hibernate resume**: `boot.resumeDevice = "/dev/mapper/cryptroot"` in host configuration.nix. Get offset: `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile`, add as `resume_offset=<N>` kernel param. raziel uses `mem_sleep_default=s2idle`; resume offset is commented out until set up. See GPU section for NVIDIA display restoration requirements.
- **Blueman applet**: HM auto-generates a drop-in that adds a second `ExecStart=` on top of the package unit → systemd refuses (not oneshot). Fix in `hosts/zaphkiel/home.nix`: `systemd.user.services.blueman-applet.Service.ExecStart = lib.mkForce [ "" "${pkgs.blueman}/bin/blueman-applet" ]`.
- **AI services (zaphkiel)**: `hosts/zaphkiel/ai-services.nix` — llama-router (port 11434), llama-embedding (port 11435), n8n (port 5678), neo4j (port 7474 HTTP / 7687 Bolt), cockpit (port 9090). Services run as `llama` system user (groups: `video`, `render`). Models at `/var/lib/llm-models/`. Neo4j: `https.enable = false; http.enable = true` (default HTTPS fails without SSL policy). Cockpit: `settings.WebService.AllowUnencrypted = "true"` + `Origins = lib.mkForce "http://localhost:9090"` + `security.pam.services.cockpit = {}` required for localhost HTTP login.
- **MIME + terminal**: `nvim.desktop` has `Terminal=true`; `TerminalApplication=ghostty` in kdeglobals routes it to ghostty.
- **State version**: `system.stateVersion = "25.11"`. Do not bump. Set options explicitly to silence HM upgrade warnings.
