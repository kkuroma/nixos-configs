# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal NixOS flake config for multiple machines. Layout:

- `flake.nix` — per-host `nixosConfigurations` declarations only. Wires inputs, `specialArgs`, home-manager, and the `niriParts` list for each host.
- `modules/` — topic-scoped NixOS system modules. **No `modules/default.nix` aggregator** — each host's `configuration.nix` explicitly imports the modules it wants by path, so future hosts can opt in/out freely.
- `hosts/<name>/` — per-host files: `configuration.nix`, `disko.nix`, `hardware-configuration.nix`, `home.nix` (host-specific HM config), `niri-outputs.kdl` (monitor layout + per-output niri layout overrides).
- `home/` — shared home-manager modules. `kuroma.nix` is a pure entry point (imports + identity only). Each concern has its own file.
- `config/` — raw static config files (non-nix). Deployed via `xdg.configFile.*.source` or `xdg.dataFile.*.source` in `home/kuroma.nix`. Subdirs: `niri/`, `fastfetch/`, `fonts/`, `noctalia/`.

Currently one host: `zaphkiel` (x86_64-linux desktop).

## Adding config — decision rules

- **Host-agnostic system config** → new file in `modules/`, add its import to each host's `configuration.nix`.
- **Host-specific system config** → edit `hosts/<name>/configuration.nix` directly, or add a module import only that host uses.
- **Shared home-manager config** → add a new file under `home/` and import it in `home/kuroma.nix`.
- **Host-specific home-manager config** → edit `hosts/<name>/home.nix`.
- **Niri config (all hosts)** → add a KDL file under `config/niri/` and add it to `niriParts` in `flake.nix`.
- **Host-specific niri config** → edit `hosts/<name>/niri-outputs.kdl`.
- **Static config files** (no Nix interpolation needed) → add raw file under `config/`, reference with `.source` in `home/kuroma.nix`. **All `.source` refs live in `kuroma.nix` for traceability — never scatter them into sub-modules.**
- **Config files needing Nix interpolation** → use `.text` in the relevant home module (e.g. `home/qt.nix` for kdeglobals/qt5ct/qt6ct, `home/ghostty.nix` for ghostty).
- **Do not write NF icons or ANSI escape sequences directly** in Nix strings — copy raw files with `.source` instead.

## Common commands

Rebuild (system + home-manager together — one command does both):
```
sudo nixos-rebuild switch --flake ~/nixos-configs#zaphkiel
```
Variants: `boot` (apply on next boot), `test` (no bootloader entry), `build` (build only).

Validate without applying:
```
nix flake check
nix build .#nixosConfigurations.zaphkiel.config.system.build.toplevel
```

Update inputs:
```
nix flake update            # all inputs
nix flake update nixpkgs    # one input
```

Initial install on a fresh machine:
```
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount ./hosts/zaphkiel/disko.nix
sudo nixos-generate-config --no-filesystems --root /mnt
# copy /mnt/etc/nixos/hardware-configuration.nix → hosts/zaphkiel/hardware-configuration.nix
sudo nixos-install --flake .#zaphkiel
```

## Architecture notes

### Disk (`hosts/zaphkiel/disko.nix`)
GPT + 1G ESP + LUKS container filling the rest. Inside LUKS: single Btrfs filesystem with subvolumes `root`, `home`, `nix`, `persist`, `swap` (64G swapfile). `compress=zstd,noatime` everywhere. NVMe `by-id` path and UUIDs are pinned here — hardware change means editing this file.

### Boot (`modules/boot.nix`)
GRUB with `enableCryptodisk = true` + EFI. Required because `/` is inside LUKS. Host-agnostic for now; move to the host directory if a future machine doesn't use FDE.

### GPU (`modules/nvidia.nix`)
`services.xserver.videoDrivers = ["nvidia"]`, `hardware.nvidia.open = true`, `nixpkgs.config.cudaSupport = true`, `hardware.nvidia-container-toolkit.enable` for Docker GPU passthrough. `allowUnfree` lives in `modules/nix.nix`. Full rebuild + reboot required when touching these. Non-NVIDIA hosts should omit this module entirely.

### nixpkgs channel
Using `github:nixos/nixpkgs/nixpkgs-unstable` (not `nixos-unstable`). The `nixpkgs-unstable` branch skips NixOS integration test gating so package updates land faster. All flake inputs use `inputs.nixpkgs.follows = "nixpkgs"` to share a single nixpkgs version.

### Desktop session (`modules/niri.nix`)
- Enables `programs.niri`, polkit, gnome-keyring.
- Login via greetd + tuigreet launching `niri-session`. `initial_session` autologins `kuroma`; `default_session` shows the TUI picker.
- System packages: noctalia (from its own flake input), xwayland-satellite, wl-clipboard, papirus-icon-theme, kdePackages.breeze (cursor).
- `XCURSOR_THEME = "breeze_cursors"`, `XCURSOR_SIZE = "24"`, and `QT_QPA_PLATFORMTHEME = "qt6ct"` set via `environment.variables`.
- Noctalia is from `inputs.noctalia` (`github:noctalia-dev/noctalia-shell`) — correct approach, do not move to nixpkgs. The flake exports `homeModules.default` and `nixosModules.default` but only the package is currently used.

### Niri config assembly
`home/niri.nix` reads `niriParts` (a list of KDL file paths from `extraSpecialArgs`) and concatenates them into `~/.config/niri/config.kdl` via `lib.concatMapStrings builtins.readFile`. Parts for zaphkiel in order:
1. `config/niri/appearance.kdl` — cursor theme (`breeze_cursors`, size 24)
2. `config/niri/input.kdl` — input device config
3. `config/niri/noctalia.kdl` — includes noctalia's runtime `noctalia.kdl`, adds corner-radius window-rule, debug block, noctalia-overview layer-rule
4. `config/niri/spawn.kdl` — kills lingering quickshell, spawns xwayland-satellite
5. `config/niri/keybinds.kdl` — all keybinds
6. `hosts/zaphkiel/niri-outputs.kdl` — monitor layout

When adding a new host, create its `niriParts` list in `flake.nix`.

### Niri config — known gotchas
- **One global `layout {}` node only**: niri errors on duplicate `layout {}` blocks. Noctalia generates one at runtime via `noctalia.kdl`. Put all layout overrides in per-output `layout {}` blocks inside `output {}` nodes instead.
- **`recent-windows { highlight }` is first-wins**: adding a second `recent-windows` block after `include "noctalia.kdl"` has no effect — niri ignores it. To disable the active-window highlight tint, use noctalia's settings UI (Settings → recent windows toggle), not the KDL config.
- **KDL inline block syntax requires semicolons**: `border { width 2; }` not `border { width 2 }`.
- **Nix path literals cannot contain spaces**: file paths used with `.source` must have no spaces. The `xdg.configFile` key (a string) can have spaces for the deployed path. Example: source file `config/noctalia/colorschemes/material-ocean/material-ocean.json` deploys to `"noctalia/colorschemes/Material Ocean/Material Ocean.json"`.

### Noctalia — theming
- Noctalia writes `~/.config/niri/noctalia.kdl` at runtime (layout colors, border colors, recent-windows highlight). Our `config/niri/noctalia.kdl` includes this file then appends static overrides.
- Noctalia writes `~/.config/ghostty/config.ghostty` (terminal palette). `home/ghostty.nix` uses `programs.ghostty` and references this via `"config-file" = "~/.config/ghostty/config.ghostty"` in settings.
- Custom color schemes go in `config/noctalia/colorschemes/<name>/` (no spaces in path) and are deployed via `xdg.configFile` in `kuroma.nix`. Currently: `material-ocean` → deploys to `~/.config/noctalia/colorschemes/Material Ocean/Material Ocean.json`.
- **VSCodium theming**: `noctalia.noctaliatheme` is installed via `home.activation.noctaliaThemeExtension` in `home/codium.nix` — a bash script that copies the nix-managed extension to `~/.vscode-oss/extensions/noctalia.noctaliatheme/` as a writable directory. A `.nix-src` sentinel file tracks the nix store path and triggers a re-copy on extension updates. It is NOT in the extensions list (HM would symlink it read-only and noctalia can't write its color theme file).
- **GTK theming**: GTK is not managed by the HM `gtk` module (causes `.gtk.css.backup` conflicts). Instead: `adw-gtk3` package installed, `dconf.settings` in `home/qt.nix` sets `gtk-theme = "adw-gtk3"` and font names. Noctalia applies its palette on top of adw-gtk3 at runtime (Settings → Color Scheme → Templates → GTK on). GTK4/libadwaita ignores `gtk-theme` and uses noctalia's color variables directly.
- **qt5ct/qt6ct color files**: `~/.config/qt6ct/colors/` and `~/.config/qt5ct/colors/` are plain directories (not HM-managed symlinks). Noctalia can freely write `noctalia.conf` there. Only `qt6ct.conf`/`qt5ct.conf` themselves are HM symlinks.

### Fonts
Font names are declared as HM module options in `home/fonts.nix`:
```nix
options.rice.fonts = {
  ui   = lib.mkOption { type = lib.types.str; default = "Google Sans Flex"; };
  mono = lib.mkOption { type = lib.types.str; default = "Google Sans Code"; };
};
```
Any home module reads them as `config.rice.fonts.ui` / `config.rice.fonts.mono`. To change fonts globally, edit the two defaults in `fonts.nix` only.

- **UI font**: Google Sans Flex (variable TTF in `config/fonts/`, installed to `~/.local/share/fonts/` via `xdg.dataFile`).
- **Mono font**: Google Sans Code (already in nixpkgs via `google-fonts` system package).
- **Fallbacks**: Noto Sans CJK/Arabic/Thai/Hebrew/Devanagari for non-Latin scripts; Noto Serif CJK for serif; Noto Color Emoji. Configured in `home/fonts.nix` fontconfig (`~/.config/fontconfig/fonts.conf`).
- **System fontconfig** (`modules/fonts.nix`): only uses `fonts.fontconfig.defaultFonts` (Noto Sans / Noto Sans Mono / Noto Color Emoji) as system-level fallbacks. `fonts.fontconfig.localConf` is NOT used — it generates invalid XML in some nixpkgs versions.
- **After adding a font file**: run `fc-cache -f` once.

### Home-manager module layout
`home/kuroma.nix` is a pure entry point — imports + identity fields only. All `.source` references to raw config files are consolidated here for traceability. Sub-modules:

| File | Contents |
|------|----------|
| `home/fonts.nix` | `rice.fonts.{ui,mono}` options, fontconfig, Google Sans Flex font file deployment |
| `home/ghostty.nix` | `programs.ghostty` — settings with font from `rice.fonts.mono`, noctalia config-file ref |
| `home/niri.nix` | Assembles `~/.config/niri/config.kdl` from `niriParts` |
| `home/apps.nix` | User packages + `programs.X.enable` for yazi/btop/mpv/zathura/neovim/fzf |
| `home/zsh.nix` | Zsh config, aliases, prompt, zoxide |
| `home/nushell.nix` | Nushell config, same aliases, two-line prompt with timing |
| `home/qt.nix` | kdeglobals, qt5ct, qt6ct as `.text`; GTK dconf settings — all use `rice.fonts.*` |
| `home/codium.nix` | VSCodium + extensions + userSettings; noctalia extension via `home.activation` |

### Apps — system vs home split
**System (`modules/apps.nix`)**: `programs.steam.enable`, plus packages needed before login or by all users: `nushell git wget curl zip unzip`. `zsh` is handled by `programs.zsh.enable = true` in `modules/users.nix` (also adds it to `/etc/shells`).

**Home (`home/apps.nix`)**: All user-facing apps. Programs with HM modules use `programs.X.enable`:
- `programs.neovim` (`withRuby = false`, `withPython3 = false`)
- `programs.yazi` (`shellWrapperName = "y"`)
- `programs.btop`, `programs.mpv`, `programs.zathura`
- `programs.fzf` (`enableZshIntegration = true` — no nushell integration option)

Always set these explicitly to silence stateVersion upgrade warnings — do **not** bump `home.stateVersion` just to silence warnings.

### Shell (zsh + nushell)
- Both shells have identical aliases. Zsh uses `programs.zsh.initContent` with `lib.mkOrder 550` for pre-compinit content (replaces deprecated `initExtraBeforeCompInit`/`initExtra`).
- `reload` alias is `exec zsh` (not `source ~/.zshrc` — re-sourcing causes double-init issues with NVM etc.).
- Nushell two-line prompt: `PROMPT_COMMAND` must end with `(char newline)` for `PROMPT_INDICATOR` to appear on the second line.
- Nushell uses `$env.USER` (not `$env.USERNAME`). `CMD_DURATION_MS` is a string — cast with `| into int` before arithmetic.
- `programs.zoxide` has both `enableZshIntegration` and `enableNushellIntegration` set to `true` (in `home/zsh.nix`).

### Static config files (`config/`)
Deployed via `xdg.configFile.*.source` or `xdg.dataFile.*.source` in `home/kuroma.nix`:

| Repo path | Deployed to | Mechanism |
|-----------|-------------|-----------|
| `config/fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` | `xdg.configFile` |
| `config/fonts/GoogleSansFlex-VariableFont.ttf` | `~/.local/share/fonts/GoogleSansFlex-VariableFont.ttf` | `xdg.dataFile` (in `fonts.nix`) |
| `config/noctalia/colorschemes/material-ocean/material-ocean.json` | `~/.config/noctalia/colorschemes/Material Ocean/Material Ocean.json` | `xdg.configFile` |

ghostty config and kdeglobals are no longer static files — they are generated as `.text` in `home/ghostty.nix` and `home/qt.nix` respectively, using `rice.fonts.*` for interpolation.

### Services (`modules/services.nix`)
Merged from what were previously `audio.nix`, `bluetooth.nix`, `ssh.nix`, `printing.nix`. Also contains tailscale and syncthing. Syncthing: `user = "kuroma"`, `dataDir = "/home/kuroma"`, one folder `Documents → ~/Documents`.

### NAS automounts (`modules/autofs.nix`)
CIFS mounts via autofs. Mounts four shares from `100.104.4.37` (Tailscale IP) under `/mnt/NAS/`: `anime`, `songs`, `backup-home`, `backup-games`. Credentials read from `/etc/autofs/nas-credentials` (created manually on the machine, not in git — `chmod 600`). `systemd.services.autofs` has `after = ["tailscaled.service"]` so it starts after the Tailscale tunnel is up.

### Fonts (`modules/fonts.nix`)
System-level font packages: `maple-mono.NF-CN`, `noto-fonts`, `noto-fonts-cjk-sans`, `noto-fonts-color-emoji`, `google-fonts` (includes Google Sans Flex and Google Sans Code), `nerd-fonts.jetbrains-mono`. `fonts.fontconfig.defaultFonts` sets Noto Sans / Noto Sans Mono / Noto Color Emoji as system fallbacks. Do NOT use `fonts.fontconfig.localConf` — it generates a file without the required XML root element in some nixpkgs versions, causing fontconfig errors.

### VSCodium (`home/codium.nix`)
- Extensions from `nix-vscode-extensions` open-vsx. `mutableExtensionsDir = true`.
- `latex-workshop` is patched with `pkgs.runCommand` to remove the engine version constraint in `package.json` (`sed` replaces `"vscode": "^X.Y.Z"` with `"vscode": "*"`). This avoids breakage when nixpkgs VSCodium lags behind the extension's declared minimum version.
- `userSettings` manages all non-color settings declaratively. Color settings (`workbench.colorCustomizations`, `editor.tokenColorCustomizations`) are excluded — noctalia's theme extension handles colors.
- Noctalia extension is NOT in the extensions list. It is installed by `home.activation.noctaliaThemeExtension` as a writable copy (see Noctalia — theming above).

### Monitors (zaphkiel)
Two 1080p@120Hz displays. Kanshi (`services.kanshi` in `hosts/zaphkiel/home.nix`) handles output positioning and hotplug. HDMI-A-2 is the primary landscape monitor; HDMI-A-1 is portrait (rotated 90°) to the right, `position x=1080 y=0`. Per-output `layout {}` blocks in `niri-outputs.kdl` control gaps, border widths, and `default-column-width`.

### Gnome Keyring / Vivaldi
`services.gnome.gnome-keyring.enable = true` is set in `modules/niri.nix`. Vivaldi prompts for keyring unlock on first launch per session; add `security.pam.services.greetd.enableGnomeKeyring = true` to auto-unlock at greetd login.

### State version
`system.stateVersion = "25.11"` in `hosts/zaphkiel/configuration.nix`. Do not bump — it pins stateful-module defaults to the install-time release. Each new host gets its own value matching when it was first installed. When HM warns about default value changes across versions, **set the option explicitly** to adopt the new default and silence the warning — do not bump `home.stateVersion`.
