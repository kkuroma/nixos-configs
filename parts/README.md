# parts/

System config, split by **how it switches on**. All four dirs are auto-imported by every host (each has a blind `default.nix`); a disabled module is inert, not absent.

| Tier | Dir | Gating | Adds to host |
|---|---|---|---|
| 1 — always-on | `universal/` | none | nothing |
| 2 — flag | `modules/` | `host.{gpu,desktop,profile,features}.X` | one line in `host = {...}` |
| 3 — parameterized | `services/` | `host.services.<name>.enable` + port/dataDir/… | a struct in `host.services` |
| multi-instance | `templates/<name>.nix` | `host.<name>.<instance>` declared | a struct per instance |

- **universal/** — Tier 1. No gates, no options. boot, locale, networking, nix, sops (framework only), users, packages, caddy.
- **templates/** — the option *declarations* (`host.*`). No behaviour, just `mkOption`. See its README.
- **modules/** — Tier 2. One file per opt-in feature, gates on a `host.*` option from `templates/system.nix`.
- **services/** — Tier 3. One file per service, gates on `host.services.<name> or null`. See its README.

**Typo trap:** `host.services` is a freeform `attrsOf`, so `host.services.jelyfin = …` silently no-ops. Verify with
`nix eval .#nixosConfigurations.<host>.config.services.<name>.enable` before deploying.
