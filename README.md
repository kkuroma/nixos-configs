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
| a multi-instance service | `parts/services/<name>.nix` (declares its own option) | `host.<name>.<instance>` |
| a per-host HM extra | `hosts/<name>/home.nix` | auto-picked by mkHost |

**Service access:** internal `https://<service>.<host>` via AdGuard DNS + Caddy `tls internal`; public via cloudflared → `localhost:80` → Caddy. Service table lives in `CLAUDE.md`.

## Directory guides

Every layer documents its own rules — start at [`parts/`](parts/README.md) for the tier model:

- [`parts/README.md`](parts/README.md) — the tier model: which dir a system concern belongs in.
- [`parts/templates/README.md`](parts/templates/README.md) — where every `host.*` option is declared, and the declare → flip → consume flow.
- [`parts/services/README.md`](parts/services/README.md) — the Tier 3 service mold (gating idiom, mandatory fields, secrets rule).
- [`home/README.md`](home/README.md) — home-manager layout, the `host.home.*` tickboxes, and the gating idiom.

## Adding & removing things

Nothing maintains an import list by hand — every dir is blind-imported, so add/remove is always "the file + the host's declaration", never an `imports` edit.

### Service (Tier 3)

**Add:**
1. Create `parts/services/<name>.nix` — the filename **is** the option key:
   ```nix
   { config, lib, ... }:
   let
     cfg = config.host.services.<name> or null;
   in
   {
     services.<name> = lib.mkIf (cfg != null && cfg.enable) {
       enable = true;
       port = cfg.port;   # thread cfg.dataDir too if stateful
     };
   }
   ```
2. In `hosts/<host>/configuration.nix`, add to the `host.services` block:
   ```nix
   <name> = { enable = true; port = ...; };   # + dataDir/storage if stateful, publicHost if public
   ```
3. `git add` the new file (flake eval won't see it otherwise), rebuild.

Caddy vhost (`https://<name>.<host>`), systemd storage ordering, and tailscale firewall openings are generated — don't write them. Secrets go inside the file's `mkIf`, never in `parts/universal/sops.nix`.

**Remove from one host:** delete its `host.services.<name>` block.
**Remove everywhere:** also `git rm parts/services/<name>.nix` (and drop its sops keys from `secrets/secrets.yaml`).

### Module (Tier 2)

**Add:**
1. Declare the flag in `parts/templates/system.nix` (or `parts/templates/home.nix` for HM bundles).
2. Create `parts/modules/<name>.nix` gated on that flag (`lib.mkIf config.host.<flag>`).
3. Flip it in `hosts/<host>/configuration.nix`: one line in the `host = { ... }` block.

**Remove:** reverse all three — host line, module file, option declaration.

### Home part

**Add:** one concern per file, dropped in the tier that matches its gate:
- `home/base/` — headless-safe, every host, no gate.
- `home/dev/` — headless-safe dev tooling; the tier import is the gate (`host.home.dev`), so the file itself has no `mkIf`.
- `home/programs/` — one configured graphical program per file (desktop-only). If it belongs to a bundle, self-gate: `config = lib.mkIf osConfig.host.home.<bundle> { ... };`.
- `home/desktop/` — session/DE integration (desktop-only).
- Install-only packages: a line in `home/packages.nix` (bundle apps via `lib.optionals osConfig.host.home.<bundle>`), not a new file.

Static config files go in `config/` and are pulled via `.source` from the owning module.
**Per-host-only HM** goes in `hosts/<host>/home.nix` (auto-picked by `mkHost`), never inline in `flake.nix`.

**Remove:** delete the file plus any `config/` files only it referenced; if it was bundle-gated, hosts unticking the bundle need no change.

### Host

**Add:** `hosts/<name>/{configuration,disko,hardware-configuration}.nix`, an entry in `machines` in `flake.nix`, and one `mkHost "<name>" { ... };` line. Add the new host's SSH key to `.sops.yaml` after first boot.
**Remove:** delete the dir, the `machines` entry, and the `mkHost` line; drop its key from `.sops.yaml`.
