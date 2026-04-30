# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal NixOS flake config for multiple machines. Layout:

- `flake.nix` — per-host `nixosConfigurations` declarations only. Wires inputs, `specialArgs`, home-manager, and the `niriParts` list for each host.
- `modules/` — topic-scoped NixOS system modules. **No `modules/default.nix` aggregator** — each host's `configuration.nix` explicitly imports the modules it wants by path, so future hosts can opt in/out freely.
- `hosts/<name>/` — per-host files: `configuration.nix`, `disko.nix`, `hardware-configuration.nix`, `home.nix` (host-specific home-manager config), `niri-outputs.kdl` (monitor layout + per-output niri layout overrides).
- `home/` — shared home-manager modules: `kuroma.nix` (identity, GTK theming, imports `niri.nix`), `niri.nix` (assembles `~/.config/niri/config.kdl` from `niriParts`).
- `config/niri/` — global KDL fragments: `appearance.kdl` (cursor theme/size), `spawn.kdl` (startup processes), `keybinds.kdl` (all keybinds).

Currently one host: `zaphkiel` (x86_64-linux desktop).

## Adding config — decision rules

- **Host-agnostic system config** → new file in `modules/`, add its import to each host's `configuration.nix` that wants it.
- **Host-specific system config** → edit `hosts/<name>/configuration.nix` directly (hostname, stateVersion, disk identity) or add a module import only that host uses.
- **Shared home-manager config** → edit `home/kuroma.nix` or add a new file under `home/` and import it there.
- **Host-specific home-manager config** → edit `hosts/<name>/home.nix`. This is imported alongside `home/kuroma.nix` in `flake.nix`. Use this for anything hardware-tied: kanshi monitor profiles, host-specific services.
- **Niri config that applies to all hosts** → add a KDL file under `config/niri/` and add it to the `niriParts` list in `flake.nix` for each relevant host.
- **Host-specific niri config** → edit `hosts/<name>/niri-outputs.kdl` (monitor layout, per-output layout overrides). Already included in every host's `niriParts`.

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

### Desktop session (`modules/niri.nix`)
- Enables `programs.niri`, polkit, gnome-keyring.
- Login via greetd + tuigreet launching `niri-session`. `initial_session` autologins `kuroma`; `default_session` shows the TUI picker.
- System packages: noctalia (from its own flake input, not nixpkgs), xwayland-satellite, wl-clipboard, papirus-icon-theme, kdePackages.breeze (cursor).
- `XCURSOR_THEME = "breeze_cursors"` and `XCURSOR_SIZE = "24"` set via `environment.variables`.
- Noctalia is from `inputs.noctalia` (`github:noctalia-dev/noctalia-shell`) so it tracks upstream rather than whatever nixpkgs has. The flake input must be passed via `specialArgs = { inherit inputs; }` for modules to access it.

### Niri config assembly
`home/niri.nix` reads `niriParts` (a list of KDL file paths from `extraSpecialArgs`) and concatenates them into `~/.config/niri/config.kdl` via `lib.concatMapStrings builtins.readFile`. The parts for zaphkiel in order:
1. `config/niri/appearance.kdl` — cursor theme (`breeze_cursors`, size 24)
2. `config/niri/spawn.kdl` — kills any lingering quickshell before starting noctalia-shell (fixes ghost process on session start), then spawns xwayland-satellite
3. `config/niri/keybinds.kdl` — all keybinds: `Mod+T` → ghostty, `Mod+Space` → `noctalia-shell ipc call launcher toggle`, window/workspace nav, audio keys
4. `hosts/zaphkiel/niri-outputs.kdl` — monitor layout: HDMI-A-2 landscape left (0,0), HDMI-A-1 portrait right (1920,0, `transform "90"`). HDMI-A-1 also has `layout { default-column-width { proportion 1.0; } }` so windows fill the portrait width and workspace up/down is the natural navigation direction.

When adding a new host, create its `niriParts` list in `flake.nix` — include the global `config/niri/` parts it needs and its own `hosts/<name>/niri-outputs.kdl`.

### Monitors (zaphkiel)
Two 1080p@120Hz displays. Kanshi (`services.kanshi` in `hosts/zaphkiel/home.nix`) handles output positioning and hotplug. Niri's `niri-outputs.kdl` duplicates position/transform at the compositor level. HDMI-A-2 is the primary landscape monitor; HDMI-A-1 is portrait (rotated 90°) to the right. Niri workspaces are per-output by default — each monitor has its own independent workspace stack (Mod+Up/Down navigates within the focused output).

### Home-manager
Wired as a NixOS module — `sudo nixos-rebuild switch` applies both system and home config in one command. `useGlobalPkgs = true` and `useUserPackages = true`. Each user's config is split:
- `home/kuroma.nix` — shared across all hosts: identity (`home.username`, `home.homeDirectory`, `home.stateVersion`), GTK theming (Papirus-Dark icons, breeze cursor), imports `home/niri.nix`.
- `hosts/<name>/home.nix` — host-specific: kanshi monitor profiles, anything else tied to that machine's hardware.

Both are merged in `flake.nix` via `users.kuroma = { imports = [ ./home/kuroma.nix ./hosts/zaphkiel/home.nix ]; }`.

### User (`modules/users.nix`)
Single normal user `kuroma` in groups `wheel networkmanager video audio docker`. `initialPassword = "temp"` — change with `passwd` after first boot (ignored on subsequent rebuilds). Default shell is zsh; `programs.zsh.enable = true` and `users.defaultUserShell = pkgs.zsh` must stay together — the program option adds zsh to `/etc/shells`.

### Apps (`modules/apps.nix`)
User-facing apps: dolphin, kdenlive, obs-studio, vesktop, prismlauncher, ffmpeg. Steam via `programs.steam.enable` (not just systemPackages — this sets up the Steam FHS environment correctly).

### Fonts (`modules/fonts.nix`)
`maple-mono.NF`, `noto-fonts`, `noto-fonts-cjk-sans` (CJK + Thai coverage), `gabarito`, `nerd-fonts.jetbrains-mono`. Google Sans is not in nixpkgs (licensing) — install manually if needed.

### Gnome Keyring / Vivaldi
`services.gnome.gnome-keyring.enable = true` is set in `modules/niri.nix`. Vivaldi prompts for keyring unlock on first launch per session; add `security.pam.services.greetd.enableGnomeKeyring = true` to auto-unlock at greetd login.

### State version
`system.stateVersion = "25.11"` in `hosts/zaphkiel/configuration.nix`. Do not bump — it pins stateful-module defaults to the install-time release. Each new host gets its own value matching when it was first installed.
