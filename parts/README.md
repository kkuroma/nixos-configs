# parts/

System config, split by **how it switches on**. All four dirs are auto-imported by every host (each has a blind `default.nix`); a disabled module is inert, not absent.

| Tier | Dir | Gating | Adds to host |
|---|---|---|---|
| 1 — always-on | `universal/` | none | nothing |
| 2 — flag | `modules/` | `host.{gpu,desktop,profile,features}.X` | one line in `host = {...}` |
| 3 — parameterized | `services/` | `host.services.<name>.enable` + port/dataDir/… | a struct in `host.services` |
| multi-instance | `services/<name>.nix` (declares its own option) | `host.<name>.<instance>` declared | a struct per instance |

- **universal/** — Tier 1. No gates, no options. boot, locale, networking, nix, sops (framework only), users, packages, caddy.
- **templates/** — the option *declarations* (`host.*`). No behaviour, just `mkOption`. See [its README](templates/README.md).
- **modules/** — Tier 2. One file per opt-in feature, gates on a `host.*` option from `templates/system.nix`.
- **services/** — Tier 3. One file per service, gates on `host.services.<name> or null`. See [its README](services/README.md).

**Typo safety:** `host.services` keys are asserted against `host.knownServices` (auto-registered from `services/*.nix` filenames), so `host.services.jelyfin = …` fails eval with "unknown service(s)" instead of silently no-opping. Corollary: a service's filename must equal its option key.

Add/remove recipes live in the [top-level README](../README.md#adding--removing-things).
