# parts/templates/

The **option declarations** — this is where every `host.*` flag is born. Files here only `mkOption`; the behaviour lives in `modules/` and `services/`. Auto-imported.

| File | Declares | Read by |
|---|---|---|
| `system.nix` | `host.gpu` / `host.desktop` / `host.profile` / `host.features` | `parts/modules/*` |
| `services.nix` | `host.services.<name>` (port, dataDir, publicHost, storage, unit, caddyExtra, publicAuto, tailscalePorts) + `host.knownServices` | `parts/services/*` + emits caddy vhosts + storage deps + tailscale0 ports |
| `home.nix` | `host.home.*` HM tickboxes (bundles default to `host.profile`) | HM modules via `osConfig` + system halves via `config` |

**Flow:** declare the option here → flip/parameterize it in `hosts/<name>/configuration.nix` → a `modules/` or `services/` file reads it and emits config.

**Multi-instance services** (`filebrowser`, `cloudflared`) are the exception: their files live in `parts/services/` and *declare their own* `host.<name>` option there, generating per-instance resources (sops + systemd + caddy) — including `host.services.<instance>` entries so the caddy/storage glue comes along automatically.

**`host.home.*` is dual-read:** system modules see it via `config`, HM sees it via `osConfig` — that's how the gaming bundle's system + HM halves stay in sync.
