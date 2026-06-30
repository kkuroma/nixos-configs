# parts/services/

Tier 3 — **opt-in + parameterized**. One file per service. Each is

```nix
cfg = config.host.services.<name> or null;
config = lib.mkIf (cfg != null && cfg.enable) { ... };
```

and reads its port / dataDir / publicHost / storage / unit from the host's
`host.services.<name>` block (declared in `parts/templates/services.nix`). Auto-imported; disabled = inert.

**Enable one:** in `hosts/<name>/configuration.nix`

```nix
host.services.<name> = {
  enable = true;
  port = ...;
  dataDir = ...;        # stateful services only
  publicHost = ...;     # if cloudflare-fronted
  storage = "zfs" | "vault" | "none";
};
```

Most fields default; only `port` (+ `dataDir` for stateful) are mandatory. The template auto-emits the Caddy vhost (`https://<service>.<host>`, `tls internal`) and systemd storage ordering.

**Rules:**
- **Service secrets** are declared *inside* the gated `mkIf`, never in `parts/universal/sops.nix`.
- Full service table (port / hosts / public domain) lives in `CLAUDE.md`.
- A service that needs more than enable+port (its own DB, custom systemd, public `.well-known`) still lives here — see `matrix.nix`, `forgejo.nix` for the awkward cases.
- Adding a service that fits the mold = drop the file + one host block. No edits to host imports.
