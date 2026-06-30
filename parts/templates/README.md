# parts/templates/

The **option declarations** — this is where every `host.*` flag is born. Files here only `mkOption`; the behaviour lives in `modules/` and `services/`. Auto-imported.

| File | Declares | Read by |
|---|---|---|
| `system.nix` | `host.gpu` / `host.desktop` / `host.profile` / `host.features` / `host.home.*` | `parts/modules/*` + HM via `osConfig` |
| `services.nix` | `host.services.<name>` (port, dataDir, publicHost, storage, unit, caddyExtra, publicAuto) | `parts/services/*` + emits caddy vhosts + storage deps |
| `home.nix` | `host.home.*` HM tickboxes (bundles default to `host.profile`) | HM modules via `osConfig` |
| `filebrowser.nix` | `host.filebrowsers.<name>` | multi-instance: emits sops + systemd + caddy per instance |
| `cloudflared.nix` | `host.cloudflared.<name>` | multi-instance: one tunnel unit + sops + yaml per instance |

**Flow:** declare the option here → flip/parameterize it in `hosts/<name>/configuration.nix` → a `modules/` or `services/` file reads it and emits config.

**Multi-instance** templates (`filebrowser`, `cloudflared`) both *declare* the option **and** *generate* per-instance resources, including `host.services.<unit>` entries so caddy + storage glue come along automatically.

**`host.home.*` is dual-read:** system modules see it via `config`, HM sees it via `osConfig` — that's how the gaming bundle's system + HM halves stay in sync.
