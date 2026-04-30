# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal NixOS flake config. Layout is split three ways:

- `flake.nix` — per-host declarations only. Each host references its own `hosts/<name>/configuration.nix`.
- `modules/` — topic-scoped NixOS modules (`audio`, `bluetooth`, `boot`, `docker`, `locale`, `networking`, `niri`, `nix`, `nvidia`, `packages`, `printing`, `ssh`, `users`). There is **no `modules/default.nix` aggregator** — each host imports the specific modules it needs by path, so future hosts can opt in/out per-machine.
- `hosts/<name>/` — per-host bits: `configuration.nix` (explicitly imports each `../../modules/<name>.nix` it wants + sets host-specific values like `networking.hostName` and `system.stateVersion`), `disko.nix`, and `hardware-configuration.nix`.

Currently one host: `zaphkiel` (x86_64-linux). `hardware-configuration.nix` is a `{ }` stub committed to git — it is regenerated per-machine by `nixos-generate-config` during install and should not be hand-edited.

When adding a new piece of system config, decide first: is it host-agnostic (→ new file in `modules/`, then add the import line to each host's `configuration.nix` that wants it) or host-specific (→ edit that host's `configuration.nix` directly). Hostname, `stateVersion`, and disk identity stay in the host directory; everything else defaults to a module.

## Common commands

Rebuild on the running system after editing config:
```
sudo nixos-rebuild switch --flake .#zaphkiel
```
Variants: `boot` (apply on next boot), `test` (no bootloader entry), `build` (build only, useful for CI-style checks).

Validate without applying:
```
nix flake check
nix build .#nixosConfigurations.zaphkiel.config.system.build.toplevel
```

Update inputs (`nixpkgs`, `disko`):
```
nix flake update            # all inputs
nix flake update nixpkgs    # one input
```

Initial install on a fresh machine (destroys the target disk — see `hosts/zaphkiel/disko.nix` for the device id):
```
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount ./hosts/zaphkiel/disko.nix
sudo nixos-generate-config --no-filesystems --root /mnt   # writes /mnt/etc/nixos/hardware-configuration.nix; copy it over hosts/zaphkiel/hardware-configuration.nix
sudo nixos-install --flake .#zaphkiel
```

## Architecture notes

- **Disk layout (`hosts/zaphkiel/disko.nix`)**: GPT with a 1G ESP and a LUKS container filling the rest. Inside LUKS is a single Btrfs filesystem with subvolumes `root`, `home`, `nix`, `persist`, and `swap` (64G swapfile). `compress=zstd,noatime` everywhere. UUIDs and the NVMe `by-id` path are pinned in this file — changing hardware means editing them here.
- **Boot (`modules/boot.nix`)**: GRUB with `enableCryptodisk = true` + EFI (`canTouchEfiVariables`). Required because `/` lives in LUKS. Currently host-agnostic; if a future host doesn't use full-disk encryption this will need to move to the host directory or become opt-in.
- **GPU/CUDA (`modules/nvidia.nix`)**: NVIDIA stack — `services.xserver.videoDrivers = [ "nvidia" ]`, `hardware.nvidia.open = true` (open kernel modules), `nixpkgs.config.cudaSupport = true`, and `hardware.nvidia-container-toolkit.enable` for Docker GPU passthrough. `allowUnfree` (in `modules/nix.nix`) is on for firmware/driver bits. Touching any of these usually means a full rebuild + reboot. For a non-NVIDIA host, drop this module from `modules/default.nix` rather than editing it in place.
- **Desktop session (`modules/niri.nix`, `modules/audio.nix`)**: SDDM (Wayland) + niri compositor + Noctalia shell + xwayland-satellite. Polkit and gnome-keyring are pulled in here because niri needs them for auth/secret prompts. PipeWire (with ALSA + 32-bit + Pulse shim) handles audio. Niri's per-user config (`~/.config/niri/config.kdl`) and Noctalia's settings (`~/.config/quickshell/noctalia/settings.json`) live in `$HOME` and are not managed by this repo — the system module only ships the binaries and the SDDM session entry.
- **User (`modules/users.nix`)**: single normal user `kuroma` in `wheel networkmanager video audio docker`, with `initialPassword = "temp"` — change with `passwd` after first boot; `initialPassword` is ignored on subsequent rebuilds. Default shell is zsh (`programs.zsh.enable = true` + `users.defaultUserShell = pkgs.zsh`); both lines must stay together — setting the default shell without enabling the program leaves zsh out of `/etc/shells`. Currently in `modules/` (so reusable across hosts); move to a host's `configuration.nix` if it should be host-specific.
- **State version**: `system.stateVersion = "25.11"` lives in `hosts/zaphkiel/configuration.nix`. Do not bump casually — it pins stateful-module defaults (databases, etc.) to the install-time release. Each new host gets its own value.
