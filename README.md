# NixOS Configs

My entire digital life materialized in code! After about 6 months in Arch, I can finally call myself a Nix user!

## Machines

- `zaphkiel` my desktop PC: Ryzen 7 7700x, RTX 3090, and 64 GB of RAM. This is my powerhouse workstation with compute capable of running local LLMs and gaming.
- `raziel` my laptop: Framework 13 Ryzen 9 AI HX 370 with 32 GB of RAM. This is my portable workstation.
- `metatron` my homelab: Ryzen 5 8600G, GTX 1650, 32 GB of RAM, and 30 TiB of effective ZFS storage. This is the low-profile box that powers my entire infrastructure.

## How it's wired

`flake.nix` holds a `machines` attrset (per-host hardware: kernel, fonts, displays, nvenc, hwdec) and a `mkHost` generator. Each host is one line under `nixosConfigurations`. `mkHost` pulls in disko + home-manager + sops, the host's `configuration.nix`, and the optional `hosts/<name>/home.nix`. HM always imports `./home` as a single entry.

Everything else is split by **how it switches on**:

```text
.
├── flake.nix          # machines attrset + mkHost generator, entry point for everything (look here first!)
├── parts/
│   ├── templates/     # Option declarations (host.gpu/desktop/profile/services/...). Auto-imported
│   ├── universal/     # Tier 1 — always included base
│   ├── modules/       # Tier 2 — opt-in via a host.* flag (gpu, desktop, gaming, features)
│   └── services/      # Tier 3 — opt-in + parameterized (host.services.<name>.enable + port/dataDir/...)
├── home/              # home-manager, one concern per file, tiered like parts/. Single entry: default.nix
├── hosts/<name>/      # per-machine: configuration.nix + disko + hardware-configuration + extra/
├── config/            # static config files, symlinked in place via home manager
└── secrets/           # sops-encrypted secret store
```

Each tier has a one-line decision rule and a `README.md` in its dir. Here's a TL;DR on how to use my modular config structure:

| I want to… | Drop a file in | Gated on |
|---|---|---|
| host-agnostic always-on config | `parts/universal/` | nothing |
| an opt-in system module | `parts/modules/` + option in `parts/templates/system.nix` | `host.{gpu,desktop,profile,features}.X` |
| a parameterized service | `parts/services/` | `host.services.<name>.enable` |
| a multi-instance service | `parts/templates/<name>.nix` | `host.<name>.<instance>` |
| a per-host HM extra | `hosts/<name>/home.nix` | auto-picked by mkHost |

**Service access:** internal `https://<service>.<host>` via AdGuard DNS + Caddy `tls internal`; public via cloudflared → `localhost:80` → Caddy. Service table lives in `CLAUDE.md`.
