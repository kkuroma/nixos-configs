# CLAUDE.md

## Writing

- Invoke the `kuroma-writing` skill **before** writing or editing any prose: comments, docstrings, markdown bodies, commit messages, findings reported in chat. Follow it. It is the authority on style and this file does not restate it.
- It governs **new** text only. Do not sweep existing files to bring old comments into line unless that cleanup is the task you were given.
- **Do not overcomment a targeted change.** A comment describes what the code does for the next reader, never what this edit changed, what it used to be, or why the author touched it. A workaround keeps its one-line reason (the upstream issue that makes the code look wrong); a diff narration does not.

## Repository layout

- `flake.nix` — `machines` attrset (per-host `kernelPackages`, `fonts`, `displays`, `nvenc`, `hwdec`) + `mkHost` generator. Each `nixosConfigurations.<name>` is one line: `mkHost "name" { extraModules = [...]; };`. Every host's HM entry is `./home` (single entry); the graphical layers gate on `host.profile == "desktop"` read via `osConfig`. No inline HM blobs.
- `lib/import-dir.nix` — blind-import helper (every `*.nix` in a dir except `default.nix`); all auto-importing `default.nix` files are one-liners calling it.
- `parts/universal/` — Tier 1. Always-on, no gates, no options. Auto-imported by every host via `parts/universal/default.nix`. Includes `boot`, `locale`, `networking`, `nix`, `sops` (framework only — secrets live with their consumer), `ssh` (sshd for ALL hosts — port 22 tailscale0-only via networking.nix; host extras like metatron's GatewayPorts stay in the host), `users`, `packages` (base CLI/net/hw toolkit), `caddy`.
- `parts/templates/` — Option declarations only (schemas, no daemons): `system.nix` (host.gpu/desktop/profile/features + assertion `profile == "desktop" → desktop != null`), `services.nix` (the `host.services.<name>` submodule + generated caddy vhosts / systemd storage deps / tailscale0 firewall ports / knownServices typo assertion), `home.nix` (host.home.* bundles). Auto-imported.
- `parts/modules/` — Tier 2. Opt-in via a flag, no other parameters. Each file gates on an option from `templates/system.nix` (or `templates/home.nix`). Auto-imported; disabled = inert. GPU (amd, nvidia, nvidia-compute), desktop (niri, kde), profile bundles (fonts, fcitx5, desktop-daemons = bluetooth/pipewire/printing/power, snapper = btrfs /home snapshots), `gaming` (Steam stack — gated on `config.host.home.gaming`, the **system half of the HM gaming bundle**: `host.home.*` is read by both system modules via `config` and HM via `osConfig`; also owns `services.envfs`), features (autofs, virtualization, codiumserver).
- `parts/services/` — Tier 3. Opt-in + parameterized. Each file uses `cfg = config.host.services.<name> or null` + `mkIf (cfg != null && cfg.enable)`. Host supplies port/dataDir/publicHost/storage/unit. Auto-imported via `parts/services/default.nix`, which also registers **filenames as the valid `host.services` keys** (`host.knownServices`) — the file name IS the option key. Multi-instance services (`filebrowser.nix`, `cloudflared.nix`, `wireguard.nix`) live here too; they declare their own `host.<name>` option.
- `hosts/<name>/` — `configuration.nix` (imports the four `parts/` dirs + `./extra` + per-host overlays, then declares one `host = { ... }` block), `disko.nix`, `hardware-configuration.nix`, optional `homepage.nix` + `homepage.png`, optional `home.nix` (host-specific HM extras — auto-picked up by `mkHost`), `extra/` (host-specific .nix files: fstab, datasets, backup, laptop, nut, etc., auto-imported via `extra/default.nix`).
- `home/` — HM modules, one concern per file, with a tiered layout mirroring `parts/`. **The machine's HM tickbox is `host.home.*`** (declared in `parts/templates/home.nix`, set in each host's `configuration.nix`, read by HM modules via `osConfig`). Bundles default to follow `host.profile` (`server`|`desktop`); a host unticks what it doesn't want (e.g. `host.home.gaming = false`).
  - `default.nix` — the **single entry point** for every host (flake imports `./home` always — no `hmEntry`/`hasNiri`). Imports `./base` always; `./dev` when `host.home.dev` (**any profile** — works on servers); the graphical layers (`packages`/`fonts`/`scripts`/`programs`/`desktop`) only when `host.profile == "desktop"`. Declares home identity + gated `.face`.
  - `base/` — headless-safe modules imported by **every** host (git, zsh, nushell). Auto-imported (blind `default.nix`).
  - `dev/` — **headless-safe** dev tooling, imported whenever `host.home.dev` (servers included): `nvim.nix` (the dev toolchain packages live in `packages.nix` under `h.dev`). Must not require a graphical session; noctalia-routing modules here carry a static fallback (see below). The tier import is the dev gate, so files inside don't `mkIf dev`.
  - `programs/` — one file per **configured graphical program** (`enable` + config; self-installs). Auto-imported, desktop-only. Bundle-specific ones self-gate with `config = lib.mkIf osConfig.host.home.<bundle> { … }` (mpv→media, vscodium→dev) — exactly like a `parts/services/*.nix` gates on its `enable`.
  - `desktop/` — session/DE integration (niri, noctalia, theming, mimeapps, kde, kde-servicemenus, vivaldi, cliphist). Auto-imported, desktop-only. `noctalia.nix` self-gates on `host.home.noctalia`.
  - `packages.nix` — THE single install-only package list, imported on **every** host; desktop core gates on profile, bundles (incl. the headless dev toolchain) via `lib.optionals h.<bundle>`. `3d-printing.nix` — BambuStudio flatpak + `.desktop` launcher hack, self-gates on `host.home."3d-printing"` (flatpak runtime in `parts/modules/flatpak.nix`; openscad comes via `packages.nix`). `scripts/` — authored shell-script packages. `fonts.nix` — `rice.fonts` option + font deployment.
  - `.source` refs live in the module that owns the concern (e.g. noctalia palettes/templates in `desktop/noctalia.nix`, fastfetch in `programs/fastfetch.nix`).
  - **noctalia routing:** modules that *require* noctalia's runtime-generated files branch on `osConfig.host.home.noctalia` and carry a static fallback for the off case — **nvim** (matugen.lua → builtin `habamax` colorscheme; base16-nvim + the matugen-placeholder activation only on the noctalia path) and **starship** (palette=noctalia + marker → a static `[palettes.fallback]`). Modules that only *optionally* theme via noctalia (ghostty/qt/fcitx5/kde) are desktop-only and still hardcode `theme = noctalia`; they'd only need a fallback on a noctalia-off *desktop*, which doesn't exist (metatron is a server, so they never load there).
- `config/` — static config files, deployed via `.source` from the owning HM module.

**Hosts:** `zaphkiel` — desktop, NVIDIA RTX, nixpkgs-unstable | `raziel` — Framework 13 AMD, nixpkgs-unstable | `metatron` — home server, r5 8500G + GTX 1650, nixpkgs-unstable

**Inputs:** nixpkgs-unstable, disko, home-manager, noctalia, nix-vscode-extensions, nixvim, sops-nix, nixos-hardware, vscodium-server.

## Decision rules

- **Adding a service** that fits the standard mold: drop `parts/services/foo.nix` (gated on `config.host.services.foo or null`), declare `host.services.foo = { enable = true; port = ...; ... }` in the host. No edits to host imports.
- **Adding a module** (system-level, opt-in): drop `parts/modules/foo.nix` (gated on a `host.X` option), add the option to `parts/templates/system.nix`, host flips the switch.
- **Adding a host**: `hosts/<name>/{disko,hardware-configuration,configuration}.nix` + entry in `machines` + one `mkHost` line in `flake.nix`. Per-host HM goes in `hosts/<name>/home.nix` (auto-picked).
- **Host-agnostic always-on system config** → `parts/universal/`.
- **Host-specific system config** → `hosts/<name>/configuration.nix` or `hosts/<name>/extra/`.
- **Service secrets** → declared inside the service file (gated on `cfg.enable`), NOT in `parts/universal/sops.nix`. The universal file holds only sops framework config (defaultSopsFile, age keys).
- **Multi-instance services** (filebrowser, cloudflared) → one file in `parts/services/` that declares its own `host.<name>` option; host says `host.<name>.<instance> = {...}`; the file emits per-instance sops + systemd + caddy. Filebrowser also registers `host.services.<instance>` entries (and their names into `host.knownServices`) to inherit caddy/storage glue.
- **Per-host HM extras** → `hosts/<name>/home.nix` (auto-imported by `mkHost` if present). Never inline in `flake.nix`.
- **Machine hardware values** → `machines.<name>` in `flake.nix`, threaded to HM via `machineConfig` specialArg. Never HM options.
- **Static files** → `config/`, `.source` from the owning HM module (`base/` if headless-safe, else `programs/`/`desktop/`); files needing Nix interpolation → `.text` in relevant module.
- **Never write NF icons or ANSI escapes** in Nix strings — use `.source` files.

## Tier model

| Tier | Lives in | Gating | Adds to host |
|------|----------|--------|--------------|
| 1 — always-on | `parts/universal/` | none | nothing |
| 2 — flag | `parts/modules/` | `host.{gpu,desktop,profile,features}.X` | one line in `host = {...}` |
| 3 — parameterized | `parts/services/` | `host.services.<name>.enable` + dataDir/publicHost/etc | a struct in `host.services` |
| Multi-instance | `parts/services/<name>.nix` | `host.<name>.<instance>` declared | a struct per instance |

**Typo-safety:** `host.services` keys are asserted against `host.knownServices` (auto-registered from `parts/services/*.nix` filenames + filebrowser instance names) — `host.services.jelyfin = ...` (typo) fails eval with "unknown service(s)". Corollary: a service's file name must equal its option key.

## Common commands

```
sudo nixos-rebuild switch --flake ~/System/nixos-configs#zaphkiel
sudo nixos-rebuild switch --flake ~/System/nixos-configs#metatron
nix flake check && nix flake update
```

After rebuild: logout+login for env/session changes; reboot for kernel/GPU/initrd.

**Never build a host's configuration.** Builds take too long. Validate with eval only:

```
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

The user runs `nixos-rebuild` themselves.

## Architecture

### Disk / Boot
GPT + 1G ESP + LUKS + Btrfs (`root`, `home`, `nix`, `persist`, `swap`). systemd-boot, `configurationLimit = 10`. metatron has no LUKS — boots automatically.

**Swapfiles:** after creation or resize: `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile` → update `resume_offset`. Use `chattr +C` + `fallocate` (not `truncate`) to avoid CoW holes.

### Kernel
- `parts/universal/boot.nix` blacklists `algif_aead` (CVE-2026-31431, unpatched in 6.12 LTS at last check).
- Per-host kernel: zaphkiel = zen, raziel = latest, metatron = LTS (latest breaks ZFS).

### GPU
- **zaphkiel** (`parts/modules/nvidia.nix`): `open = true`. `powerManagement.enable = true` + `NVreg_PreserveVideoMemoryAllocations=1` required for display after hibernate.
- **CUDA is opt-in per package — never set `nixpkgs.config.cudaSupport` globally.** The global flag rewrites every derivation with a `cudaSupport` knob, and cache.nixos.org only ever builds the `cudaSupport = false` variants, so the whole media stack falls off the cache: `opencv` → `frei0r` → `mlt` → `krita`/`kdenlive`, plus `ffmpeg-full` → `whisper-cpp`. ~3h of compiling, and **`frei0r` cannot build at all** (nixpkgs puts `cudaPackages.cuda_nvcc` in `buildInputs` under `strictDeps = true`, so `nvcc` never lands on `$PATH` and CMake's `FindCUDAToolkit` aborts — CUDA-opencv's cmake config forces that lookup on every consumer). Hydra never catches it because Hydra doesn't build CUDA variants.
  - The only consumer that wants it is `parts/services/llama.nix`: `llamaCpp = pkgs.llama-cpp.override { cudaSupport = true; }`.
  - **NVENC/NVDEC are not CUDA.** `withNvenc`/`withNvdec`/`withCuvid`/`withCuda`/`withCudaLLVM` are gated on `withNvcodec` (nv-codec-headers) and are on in the stock cached ffmpeg; they dlopen the driver at runtime. Only `cuda-nvcc` and `libnpp` follow `config.cudaSupport`, and `cuda-llvm` already compiles the CUDA filter kernels. So hardware encode (kde-servicemenus `h264_nvenc`), mpv `nvdec-copy`, OBS and kdenlive render profiles all work with CUDA off. Krita has no CUDA code at all — its acceleration is the OpenGL canvas.
- **raziel + metatron** (`parts/modules/amd.nix`): `hardware.graphics`, `amd_pstate=active`.
- **metatron** (`parts/modules/nvidia-compute.nix`): GTX 1650 headless CUDA. `modesetting.enable = false`, `open = false` (Turing TU117).

### metatron ZFS (`tank`)
RAIDZ1 on 4× WD Red 12TB. Datasets managed via `hosts/metatron/extra/datasets.nix` — systemd oneshot `zfs-datasets.service`.

**Gotchas:**
- `zfs-datasets.service` is **first-creation only** — it tolerates `zfs create` failures (`|| true`) so re-runs are no-ops, but it does NOT update existing dataset properties idempotently. To change a quota/reservation, do it manually with `zfs set`. The service exists so a new metatron-shaped host can bootstrap cleanly.
- `chown` uses `|| true` — restart `zfs-datasets.service` then the service if ownership silently failed (service user didn't exist on first run).
- **Quota/reservation reduction:** ZFS refuses to lower quota below current reservation. Fix: `zfs set reservation=none tank/<dataset>` first, then rebuild.

### NAS / SMB
Samba binds to `lo ${metatronIP}` only. Passwords in sops as `samba/{kuroma,ct,pt}`, set via `samba-passwords` oneshot. SMB users: `ct` (uid 1001), `pt` (uid 1002).

`samba-passwords.service` refuses to run if a sops secret is empty/missing (`[ -s ${secret} ]` guard) — avoids silently zero-passwording an account if sops fails to materialize.

### Services

`parts/universal/caddy.nix` enables caddy + base certs. `parts/templates/services.nix` defines `host.services.<name>` (port, dataDir, publicHost, storage, unit, caddyExtra, publicAuto, tailscalePorts) and emits the caddy vhosts + systemd storage deps + tailscale0 firewall openings. Each `parts/services/*.nix` is gated on `cfg.enable` and reads its parameters from the host's declaration.

| File | Service | Port | Default hosts | Public domain |
|------|---------|------|---------------|---------------|
| `adguard.nix` | AdGuard Home | DNS :53, web :3000 | metatron, zaphkiel | — |
| `beszel.nix` | Beszel hub (+ loopback agent) | :8090 | metatron, zaphkiel | — |
| `uptime-kuma.nix` | Uptime Kuma | :3001 | metatron | — |
| `jellyfin.nix` | Jellyfin | :8096 | metatron | — |
| `navidrome.nix` | Navidrome | :4533 | metatron | — |
| `searxng.nix` | SearXNG | :8888 | metatron | searx.kuroma.dev |
| `privatebin.nix` | PrivateBin | :8082 | metatron | pastebin.kuroma.dev |
| `stirling-pdf.nix` | Stirling PDF | :8085 | metatron | pdf.kuroma.dev |
| `nextcloud.nix` | Nextcloud | :8081 | metatron | cloud.kuroma.dev |
| `matrix.nix` | Matrix Synapse | :8448 | metatron | matrix.isomorphic.to (publicAuto=false: handles .well-known) |
| `postgresql.nix` | PostgreSQL | — | metatron, zaphkiel | — |
| `vaultwarden.nix` | Vaultwarden | :8222 | metatron | vault.kuroma.dev |
| `forgejo.nix` | Forgejo | :1412 | metatron | git.kuroma.dev |
| `hosts/metatron/extra/nut.nix` | NUT (UPS) | :3493 | metatron | — (localhost only) |
| `syncthing.nix` | Syncthing | :8384 | zaphkiel, raziel | — |
| `cockpit.nix` | Cockpit | :9090 | zaphkiel, raziel | — |
| `n8n.nix` | n8n | :5678 | zaphkiel | — |
| `sonarr.nix` | Sonarr | :8989 | zaphkiel | — |
| `radarr.nix` | Radarr | :7878 | zaphkiel | — |
| `neo4j.nix` | Neo4j | :7474/:7687 | zaphkiel | — |
| `llama.nix` | LLaMA router | :11434 | zaphkiel | — |
| `librechat.nix` | LibreChat | :3080 | zaphkiel | — |
| `graphiv.nix` | GraphIV MCP | :8756 | zaphkiel | — |
| `hosts/<name>/homepage.nix` | homepage-dashboard | :8083 | metatron, zaphkiel | — |
| **`parts/services/filebrowser.nix`** | FileBrowser (multi) | :8200+ | metatron (ct-dump) | ct-dump.kuroma.dev |
| **`parts/services/cloudflared.nix`** | cloudflared tunnel (multi) | — | metatron (main), zaphkiel | — |
| **`parts/services/clamav.nix`** | ClamAV NAS scan (`host.clamav`) | — | metatron | — |
| **`parts/services/wireguard.nix`** | WireGuard tunnels (`host.wireguard`, multi) | — | raziel, zaphkiel | — |

**Service access model:** Internal: `https://<service>.<hostname>` via AdGuard DNS + Caddy `tls internal`. Public: cloudflared → `localhost:80` → Caddy. DNS rewrites: `*.metatron → 100.107.220.115`, `*.zaphkiel → 100.91.235.104`, `*.raziel → 100.79.72.120`.

**Enabling a service:** the host's `configuration.nix` declares `host.services.<name> = { enable = true; port = ...; dataDir = ...; publicHost = ...; storage = "zfs" | "vault" | "none"; unit = ...; };`. Most fields have sensible defaults; only port + (dataDir for stateful services) are mandatory. `tailscalePorts = [ ... ]` opens raw ports on tailscale0 for clients that bypass caddy (zaphkiel: llama 11434, neo4j bolt 7687) — no hand-written firewall lines in host configs. Service secrets are declared inside the gated `mkIf` of the service file, not in `parts/universal/sops.nix`.

### AdGuard (`parts/services/adguard.nix`)
- `bind_hosts = [ "0.0.0.0" ]` — firewall restricts DNS to `tailscale0` on all hosts, so `0.0.0.0` is safe and works regardless of which host is running the service.
- `mutableSettings = true`. **Admin password is non-declarative** — lives in `/var/lib/AdGuardHome/AdGuardHome.yaml` under `users:`. To set/reset: stop service, edit file with a bcrypt hash (`htpasswd -bnBC 10 "" yourpassword | tr -d ':\n'`), restart.
- **Fresh-install footgun:** on a from-scratch metatron, AdGuard boots into the public setup wizard with no auth until the YAML is hand-edited. Make this the first post-rebuild step.

### LLaMA (`parts/services/llama.nix`)
- Router code lives in its own flake: `git+https://git.kuroma.dev/kkuroma/llama-router` (input follows nixpkgs; module imported in `mkHost`, exposes `services.llama-router`). `parts/services/llama.nix` is thin wiring: model presets + `host.services.llama` glue, gated as before.
- Router on :11434 (binds `0.0.0.0`, firewall scopes to tailscale0). Caddy exposes it via `llama.${host}`.
- Active on zaphkiel only. Models live flat under `/Vault/llm-models/*.gguf` — unit gets `Vault.mount` ordering via `host.services` storage glue (unit `llama-router`, user `llama`).
- **Prompt caching** is llama.cpp's, not the router's: the router forwards bodies verbatim, so a repeated prefix is reused whether or not the client sets `cache_prompt` (llama.cpp defaults it on). At 16k tokens the next turn costs 0.38 s instead of 5.0 s on Gemma-4-26B, and 0.42 s instead of 17.4 s on Wordslop-Qwen3.6-27B. A cached turn costs about the same at any length, so the saving grows with the window: at full context it is 0.16 s instead of 65 s on Gemma (131k) and 1.7 s instead of 574 s on Wordslop (262k).
  - `cram` (`--cache-ram`, MiB) caps host memory for conversations that are not in a slot, per llama-server process. It is a cap and not an allocation, and llama.cpp has **no time-based expiry**: size and LRU are the only controls.
  - **Cost per held conversation is a fixed part plus a part that grows with the prompt, so never extrapolate a bytes-per-token figure from a short prompt.** At `ctk/ctv = q4_0`, Gemma-4-26B is 176 MiB + 5.7 KiB/token (268 MiB at 16k, 909 MiB at its full 131k) and Wordslop-Qwen3.6-27B is 766 MiB + 30.2 KiB/token (1250 MiB at 16k, 8500 MiB at its full 262k). The 9x spread is attention geometry, readable from the GGUF header: Gemma marks 25 of 30 layers sliding at `sliding_window = 1024`, so only 5 full-attention layers grow, while the Qwen hybrid sets `full_attention_interval = 4` and holds fixed-size SSM state on the rest. At `cram = 4096` Wordslop held two 16k conversations and a third made it thrash to zero reuse; 16384 held all six. Set `cram` per model when one model's KV is much heavier than the rest.
  - `--cache-reuse` is useless here: every model in the preset list has a sliding-window or hybrid context, so llama.cpp disables KV shifting (`cache_reuse is not supported by this context` in the journal). A prompt edited anywhere but the tail reprocesses from the edit onward.
  - Eviction kills the process, so a model swap discards its whole prompt cache. Alternating two models in LibreChat pays cold prompt processing every switch.
  - `scripts/benchmark-prompt-cache.py` in the router repo measures both (reuse pass + capacity pass) against a live instance.
  - **The budget is per model: `cram = 16384` (16 GiB) in `presetGlobals` as the default, and `cram = 32768` (32 GiB) inside the `Wordslop-Qwen3.6-27B` model block.** 16 GiB holds 18 Gemma conversations at 131k but only 1 Wordslop at 262k, which would thrash to zero reuse the moment two long Wordslop chats alternate; 32 GiB holds 3. **The caps do not compound**, because `cram` is per llama-server process and `models-max = 1` keeps one model loaded, so only the loaded model's cap is ever live. Headroom check: 3 held Wordslop conversations measured 29.3 GiB steady with a 37.8 GiB peak during slot swaps, against 61 GiB of host RAM and about 6 GiB used by everything else on zaphkiel.
  - **Migration, two steps, after the router change is pushed and `nix flake update llama-router` runs.** The router repo gained `services.llama-router.promptCache = { enable, ramMiB, ramMiBPerModel, reuseChunk, checkpoints, checkpointMinStep }`, but this repo's flake input is pinned to a commit without it, so both values are currently spelled as raw INI keys that the pinned module already passes through. Once the input moves: `presetGlobals.cram = 16384` becomes `promptCache.ramMiB = 16384;`, and the `cram = 32768` line in the Wordslop model block becomes `promptCache.ramMiBPerModel = { "Wordslop-Qwen3.6-27B" = 32768; };`. Precedence in the new module is model key > `ramMiBPerModel` > `presetGlobals` > `promptCache`, and `ramMiBPerModel` writes `cram` into the model's own section rather than `[*]`, so every spelling produces the same INI and none breaks the others. An assertion rejects a `ramMiBPerModel` key that is not a real model name.

### LibreChat + GraphIV MCP (`parts/services/librechat.nix`, `parts/services/graphiv.nix`)
zaphkiel-only demo stack: LibreChat (nixpkgs module) fronts the local llama-router (custom endpoint,
`fetch: true`, default model `Gemma-4-26B`) and mounts the GraphIV MCP server for arXiv deep research.

- **Secrets:** `secrets/librechat.yaml` — a separate sops file (CREDS_KEY/CREDS_IV/JWT_SECRET/JWT_REFRESH_SECRET/meili-master-key).
  Created by encrypting a fresh plaintext with the repo's public age keys (`nix run nixpkgs#sops -- -e -i`);
  no private key needed. Wired via `services.librechat.credentials` (systemd LoadCredential — root reads them).
- **Mongo:** `enableLocalDB = true` + `services.mongodb.package = pkgs.mongodb-ce` (prebuilt; stock
  `pkgs.mongodb` is an hours-long unfree source build).
- **MCP transport is streamable-http, not stdio** — the librechat unit runs with `ProtectHome=true`,
  so it cannot spawn a server out of `/home`. GOTCHA: `Domain "…" is not allowed` at MCP init means
  the SSRF guard — with no `mcpSettings.allowedDomains` in librechat.yaml, LibreChat fail-closes on
  SSRF-prone targets **including loopback**; the settings block allowlists
  `http://127.0.0.1:8756` explicitly. `graphiv-mcp` (unit in `graphiv.nix`) runs
  `serve_mcp.py --http` on `127.0.0.1:8756` inside the GraphIV repo's `nix develop` env as user
  `kuroma` (project venv + CUDA + peer-auth Postgres come from the dev shellHook), starting the
  project PG first if down. librechat.yaml points at `http://127.0.0.1:8756/mcp` with
  `timeout = 7200000` ms — `deep_research` legitimately holds a tool call for minutes.
- **Meilisearch** (conversation search): `services.librechat.meilisearch.enable` — the nixpkgs module
  wires SEARCH/MEILI_HOST/MEILI_MASTER_KEY + ordering; we supply
  `services.meilisearch.masterKeyFile` from sops `librechat/meili-master-key`. When the host sets a
  dataDir, the index moves to `dirOf dataDir + /meilisearch` (`/Vault/meilisearch`) with a static
  `meilisearch` user (module's DynamicUser can't own /Vault dirs) + Vault.mount ordering. Index is
  disposable — librechat re-syncs it from mongo.
- **Email** (password reset): zoho SMTP, same account/secret as vaultwarden+NUT
  (`vaultwarden/smtp-password`, shared secrets.yaml) via LoadCredential; `ALLOW_PASSWORD_RESET=true`.
- **Web search:** provider = metatron's searxng over tailscale (`SEARXNG_INSTANCE_URL=http://metatron:8888` —
  MagicDNS name, not the raw IP; searxng.nix binds 0.0.0.0 + enables `search.formats=[html json]`, metatron
  opens 8888 via `tailscalePorts`). `rerankerType = "none"`. Scraper = self-hosted firecrawl at
  `http://uriel:3002` (`firecrawlApiKey` is a dummy — schema requires it, self-hosted ignores it).
- **First-run:** register an account at `https://librechat.zaphkiel` (ALLOW_REGISTRATION=true — flip
  off once accounts exist), pick the llama-router endpoint, attach the `graphiv` MCP in the tools menu.
- First `graphiv-mcp` start may realize the dev shell (TimeoutStartSec=15min).
- **State on /Vault:** librechat `dataDir = /Vault/librechat`, mongo `dbpath = /Vault/mongodb`
  (derived as `dirOf dataDir + /mongodb`; mongodb gets explicit `Vault.mount` ordering — the
  host.services glue only orders `cfg.unit`). GraphIV's `data/` is a symlink to
  `/Vault/graphiv/data` (repo-relative paths resolve through it; PG socket stays at `<repo>/.pg`).

### Monitoring — Beszel + Uptime Kuma
- **Beszel** (`parts/services/beszel.nix`): independent hub per host (metatron + zaphkiel), each monitoring only its own machine. First admin is seeded from sops `beszel/{email,password}` via `USER_EMAIL`/`USER_PASSWORD` in the hub env file (ignored once the account exists). State in `/var/lib/beszel-hub` (StateDirectory) — deliberately off tank/Vault so monitoring survives pool trouble.
- **Beszel agent pairing is fully automated** — no GUI steps. `beszel-agent-key.service` derives the hub's public key (`ssh-keygen -y` on `/var/lib/beszel-hub/beszel_data/id_ed25519` — the hub never writes a `.pub`) into `/run/beszel/agent-key.pub` for the agent's `KEY_FILE`; `beszel-register-localhost.service` logs into the PocketBase API with the sops creds and idempotently creates the `localhost:45876` systems record. The register script is coupled to beszel's collection schema (name/host/port text, `users` relation, `status` select) — revisit on major beszel upgrades; it fails loudly in the journal, worst case is one manual Add System.
- **Uptime Kuma** (`parts/services/uptime-kuma.nix`): metatron, :3001. Deliberately GUI-managed: admin account via the setup wizard on first visit, monitors/notifications in the UI; state in `/var/lib/uptime-kuma`. (Declarative monitors via AutoKuma were tried and removed by choice — the sops `uptime-kuma/{admin-username,admin-password}` entries linger unused.)

### PostgreSQL
`parts/services/postgresql.nix` reads `dataDir` + `storage` from the host's `host.services.postgresql` block — no host-name branching. metatron sets `/tank/services/postgresql` + `storage = "zfs"`; zaphkiel sets `/Vault/postgresql` + `storage = "vault"`. Each consumer service manages its own DB.

**NixOS 25.11:** `ensureUsers`/`ensureDatabases` run in `postgresql-setup.service`. Custom SQL and dependent services need `after = [ "postgresql-setup.service" ]`; custom SQL in `lib.mkAfter` on `postStart`. **Matrix DB:** omit `ensureDBOwnership`, use `WITH OWNER=` in `CREATE DATABASE` SQL instead (Synapse requires `LC_COLLATE=C`).

### FileBrowser (multi-instance)
Declare instances in the host: `host.filebrowsers.<name> = { port = ...; root = ...; user = ...; group = ...; };`. `parts/services/filebrowser.nix` generates a hardened systemd unit + sops secrets + a `host.services.<instance>` entry (so caddy + storage glue come along, and the host's cloudflared instance picks up the public hostname automatically). Public hostname defaults to `<name>.kuroma.dev`.

- Per-instance sops secrets: `filebrowser/<name>/username`, `filebrowser/<name>/password`.
- **Init is one-shot:** `ExecStartPre` runs only when the SQLite DB doesn't exist. Rotating the sops password does NOT update the DB. To rotate: `sudo -u <user> filebrowser users update <name> --password <new> -d /var/lib/filebrowser-<name>/database.db`.

### Homepage (`hosts/<name>/homepage.nix`)
Port :8083. Wallpaper at `hosts/<name>/homepage.png` — must `git add` before building. Palettes: metatron = Everforest dark, zaphkiel = Catppuccin Mocha.

**Critical gotchas:**
- `settings.layout` must be a **list** of single-key attrsets (not an attrset — attrsets sort alphabetically).
- Do NOT set `max-width` on `#page_wrapper` — clips backdrop-blur. Use `width: 100%`.
- Info widget DOM: resources and datetime/search/weather are in **separate flex containers** — CSS `order` does NOT work across them.
- Glances widget broken in 1.7.0 — disabled on all hosts.
- NUT "peanut" widget requires Peanut2 REST server (not in nixpkgs) — not configured.
- metatron `BindReadOnlyPaths`: list each ZFS child dataset individually.

### Forgejo (`parts/services/forgejo.nix`)
Port :1412. SSH on :22 via system sshd (tailscale only). Clone URL: `forgejo@metatron:kuroma/<repo>.git`. State at `/tank/services/forgejo`. Theme: Natsumikan (custom CSS + Google Sans Flex, symlinked from Nix store via `ExecStartPre`). Icon: `parts/services/icon.webp` → PNG via imagemagick at build time.

**Gotchas:**
- `services.forgejo.secrets` is `attrsOf (attrsOf path)` — `{ section.KEY = path; }`. Use `lib.mkForce`.
- `forgejo-secrets.service`: set `ReadWritePaths = lib.mkForce []` — it's a no-op (sops secrets never empty).
- `customDir` doesn't exist on fresh ZFS — `forgejo-init-dirs` oneshot creates it.
- `loadOAuth2From()` writes `app.ini` on startup but pre-start sets it read-only — fix: `ExecStartPre = lib.mkAfter [ "+chmod u+w .../app.ini" ]`.
- App name: `settings.DEFAULT.APP_NAME` (old `appName` option removed).
- **Actions runner:** registration token from `/-/admin/runners`, stored as `forgejo/runner-token` in sops. `tokenFile` expects `KEY=VALUE` — use `sops.templates."forgejo-runner-env"` with `TOKEN=<placeholder>`.
- **SSH user:** system user is `forgejo`, not `git`. Set `settings.server.SSH_USER = "forgejo"` or `git@` clone URLs will fail (no `git` system user exists).
- **SSH keys:** Forgejo writes registered keys to `${stateDir}/.ssh/authorized_keys`; system sshd reads it via `%h/.ssh/authorized_keys`. Keys added via web UI at `https://git.kuroma.dev/user/settings/keys`.
- **sshd hardening:** `services.openssh.extraConfig` adds a `Match User forgejo` block disabling agent/TCP/stream forwarding, PTY, X11, and tunnels. Defense-in-depth in case a key ever lands in `authorized_keys` without the standard `command="forgejo serv …"` prefix — the session is still unusable as a pivot.
- **Push mirror to GitHub:** repo Settings → Mirror Settings → Add Push Mirror → HTTPS URL + GitHub PAT (`repo` scope). Forgejo is source of truth; GitHub is mirror.

### NUT (`hosts/metatron/extra/nut.nix`)
Module namespace is `power.ups` (not `services.nut`). Hardware: generic MEC0003 UPS (vendor `0001:0000`, Megatec Q1 protocol) — driver `blazer_usb`. upsd listens on `127.0.0.1:3493`.

- **70% shutdown:** systemd timer polls `upsc` every minute; shuts down if status contains `OB` and charge < 70%.
- **Email alerts:** upsmon `NOTIFYCMD` + msmtp → smtp.zoho.com → `contact@kuroma.dev` on ONBATT/ONLINE/LOWBATT/COMMBAD/COMMOK/SHUTDOWN. Reuses `vaultwarden/smtp-password`.
- Sops: `nut/monitor-password`. `upsc` reads are unauthenticated from localhost.

### Stirling-PDF (`parts/services/stirling-pdf.nix`)
`DynamicUser=true` plus full systemd hardening: `NoNewPrivileges`, `ProtectHome`, `ProtectKernel{Tunables,Modules,Logs}`, `ProtectControlGroups`, `ProtectClock`, `ProtectHostname`, `ProtectProc=invisible`, `LockPersonality`, `RestrictNamespaces`, `RestrictRealtime`, `RestrictSUIDSGID`, `RestrictAddressFamilies = AF_UNIX AF_INET AF_INET6`, `DevicePolicy=closed`, `PrivateDevices`.

`MemoryDenyWriteExecute` is **intentionally omitted** — the JVM JIT needs W+X. If Stirling fails to start after a rebuild, check journalctl for sandbox denials; the most likely culprit is `RestrictNamespaces` or `ProtectKernelLogs`.

### Syncthing (`parts/services/syncthing.nix`)
`ExecStartPost` waits for the API, then PATCHes the GUI password from `sops:syncthing/password`. The JSON body is built with `jq -Rn --arg p` — passwords containing `"`/`\`/newlines are safe. The `syncthing/password` sops secret is declared inside the gated `mkIf` (so metatron, which doesn't enable syncthing, doesn't provision it). Device addresses use the `zaphkielIP`/`razielIP` specialArgs rather than literal IPs.

### Cloudflare tunnel
Multi-instance via `parts/services/cloudflared.nix`. Declare per host: `host.cloudflared.<name> = { tokenSecret = "..."; };` — `hostnames` **defaults to every enabled `host.services` publicHost on that host** (filebrowsers included), so making a service public = set its `publicHost` + point the hostname at `http://localhost:80` in the CF dashboard; override `hostnames` only for names served outside `host.services`. Each instance gets its own systemd unit `cloudflared-<name>` + per-instance sops secret + a `pkgs.formats.yaml`-generated config; token read via `--token-file`. Currently: metatron `main` (`cloudflared/metatron-token`) → searx/pdf/pastebin/cloud/ct-dump/vault/git.kuroma.dev + matrix.isomorphic.to; zaphkiel `zaphkiel` (`cloudflared/zaphkiel-token`) → graphiv.kuroma.dev. Domains: `kuroma.dev` (services), `isomorphic.to` (Matrix). Adding cloudflared to another host = one declaration block + a new sops secret.

**Public service notes:**
- `ct-dump.kuroma.dev`: dumping ground, low-trust by design.
- `searx.kuroma.dev`: relies on Cloudflare bot protection (intentional, no in-host rate limiting).
- `pdf.kuroma.dev`: same model. Stirling is hardened (see above) but parses untrusted input — candidate for shutdown if usage is rare.

### ClamAV NAS scanning (`parts/services/clamav.nix`)
Self-declaring `host.clamav` option (no port, no vhost, so it stays out of `host.services` and `knownServices`, same pattern as cloudflared). Metatron-only: a daily scan of `/tank/nas/ct/dump` (the public-facing filebrowser dump, the only untrusted drop point; the rest of the NAS is trusted) with infected files moved to `/tank/quarantine`.

- **Engine:** resident `clamd` (unprivileged `clamav` user, holds the signature DB in RAM) plus the `freshclam` updater. The scan is a root oneshot (`clamav-scan.service` + daily timer) running `clamdscan --multiscan --fdpass --infected --move`. `--fdpass` means the root client opens the files and hands the daemon fds, so clamd never needs read access to ct/pt data and the risky parsers stay unprivileged. `--move` unlinks the original, so the unit needs write on the scan dirs too.
- **Daemon limits raised** for a NAS (`MaxFileSize 1000M`, `MaxScanSize 2048M`); the stock 25M default silently skips larger files.
- **Hardening:** the root scan unit is boxed with `ProtectSystem=strict` + `ReadWritePaths` limited to the scan paths plus quarantine, `NoNewPrivileges`, `RestrictAddressFamilies`. A socket or permission failure at scan time points here first (same failure mode as Stirling).
- **Quarantine** is a plain `0700 root` dir via tmpfiles, not a ZFS dataset, so a cross-dataset `--move` is a copy plus unlink.
- **Email on detection:** own `msmtp-clamav` sops template reusing `vaultwarden/smtp-password` (zoho), mailed to `contact@kuroma.dev`. Detection exits the unit 0 (it is a successful job), so the timer keeps firing.
- **First boot:** `clamd` will not start until `freshclam` has pulled the DB once; if `clamav-daemon` fails on a fresh box, run `freshclam` then restart it.
- **Test:** write an EICAR string into `/tank/nas/ct/dump`, `systemctl start clamav-scan`, confirm it lands in `/tank/quarantine` and an alert mail arrives.

### Networking
SSH on `tailscale0` only: sshd config in `parts/universal/ssh.nix`, port opened in `parts/universal/networking.nix`. Syncthing ports (TCP/UDP 22000 + UDP 21027, global) are declared inside `parts/services/syncthing.nix` — only hosts running syncthing open them. Per-service tailscale0 ports come from `host.services.<name>.tailscalePorts` (zaphkiel: llama 11434 — router binds 0.0.0.0, Caddy also reverse-proxies; neo4j bolt 7687).

### WireGuard (`parts/services/wireguard.nix`)
Multi-instance, NM-native, self-declaring `host.wireguard.<name>` (same pattern as cloudflared: no port, no vhost). Options: `interface`, `id`, `autoconnect`, `secretPrefix`, `localSubnets`, `refuseFrom`, `localPriority`, `endpointPriority`. **Every field of the peer's `.conf` lives in sops** under `<secretPrefix>/` (default `wireguard/<name>`): `private-key`, `address`, `dns`, `peer-public-key`, `preshared-key`, `allowed-ips`, `endpoint`. Nothing about the tunnel reaches the store or the public GitHub mirror.

**Active: `yggdrasil` on raziel + zaphkiel** — `interface = "ygg0"`, `id = "YggdrasilWG"`, `localSubnets = [ "10.10.0.0/16" ]`, `refuseFrom = [ "10.10.30.0/24" ]`. Split tunnel into a friend's server (co-hosted with haruto, UniFi WG server) reaching the internal `10.10.0.0/16` (e.g. Proxmox `10.10.30.10:8006`), while Tailscale + normal internet stay direct. **Both hosts share one client config** (one keypair, one tunnel address): bring only one up at a time, or the server's peer entry flaps between the two endpoints. Give a host its own credentials by pointing its `secretPrefix` at a separate subtree.

**Design:**
- **NetworkManager-native**, not `networking.wireguard.*`. The profile is named after the **attribute key** (`yggdrasil`), NOT the connection `id` (`YggdrasilWG`).
- `autoconnect = false` — brought up manually with `nmcli connection up yggdrasil`.
- **Split, not full:** `allowed-ips` must be typed into sops in NM keyfile syntax (`10.10.0.0/16;`, trailing `;` required), not the comma syntax of a `.conf`; same for `dns`. Nix cannot rewrite a sops value, so what you type is what lands in the keyfile. Overlaps a host's own `10.10.x` LAN harmlessly — longest-prefix match keeps the local `/24` direct, only *other* subnets tunnel.
- `ipv4.never-default = "true"`, `ipv6.method = "disabled"`.

**Secrets → keyfile:** `sops.templates."wg-<name>.env"` renders `WG_<NAME>_<FIELD>` (e.g. `WG_YGGDRASIL_PRIVATE_KEY`), instance-scoped so two tunnels can't collide in the one `EnvironmentFile` set. `NetworkManager-ensure-profiles.service` runs `envsubst` over the generated ini and writes **`/run/NetworkManager/system-connections/<attr>.nmconnection`** (0600 root) — NOT `/etc/NetworkManager/system-connections/`. The peer public key is substituted **in the section header** (`[wireguard-peer.$WG_YGGDRASIL_PEER_PUBLIC_KEY]`); envsubst rewrites the whole file, headers included. Peer block needs both `preshared-key` and `preshared-key-flags = "0"`.

**Tailscale carve-out (`dispatcherScripts`):** when a Mullvad exit node is active, table 52 holds `default dev tailscale0` which would swallow the handshake packets to the endpoint. A dispatcher tied to the tunnel's interface up/down reads the `endpoint` secret, strips the `:port` (so an **IPv4 literal is assumed** — a DNS-name endpoint would have to be resolved first), and adds `ip rule add to <endpoint>/32 lookup main priority 5260` (just below tailscale's `lookup 52` at 5270) so handshakes leave via the physical route. Removed on down; survives reboots + tailscale restarts (tailscale never touches a rule it didn't create). Harmless on hosts with no exit node.

**Verifying a handshake:** `ip -s -h link show ygg0` (no sudo) — **RX > 0 == handshake completed**. RX=0 / TX>0 == our inits get no reply (server-side: port not forwarded, `wg` not listening, or pubkey not registered — check with `sudo wg show` / `sudo ss -ulpn | grep 51820` on Yggdrasil).

**Adding a tunnel (or a host):** one `host.wireguard.<name>` block in the host's `host = { ... }`, plus the seven fields under `wireguard/<name>/` in sops. No firewall changes (client-initiated), no port to open.

**Gotchas:**
- The `.conf` from haruto is plaintext (private key) — never paste it anywhere public; the repo is push-mirrored to GitHub, so it lives in sops only.
- After editing the source, a `build` is not a `switch` — verify the deployed keyfile with `sudo cat /run/NetworkManager/system-connections/yggdrasil.nmconnection` shows substituted values (no literal `$WG_*`), not just that a fresh build is correct.
- A missing or empty sops field renders an empty env var and `envsubst` writes it silently; the profile then fails to activate (or comes up with no peer) rather than erroring at build time.

### Autofs / Backups (zaphkiel)
Autofs mounts `anime`, `music`, `kuroma`, `research` from metatron via CIFS. rsync timers in `hosts/zaphkiel/extra/backup.nix` push anime (6h), movies (6h), music (6h), research (weekly), home (6h → `metatron:/tank/nas/kuroma/home/` over SSH). All jobs rsync directly to metatron over SSH — no SMB intermediary.

**Media layout:** `vault/media/anime` → `/mnt/Vault-Storage/media/anime` (Sonarr), `vault/media/movies` → `/mnt/Vault-Storage/media/movies` (Radarr). Mirrored on metatron as `tank/media/anime` (3T) and `tank/media/movies` (1T). Keep anime and movies in separate datasets — Sonarr manages anime/shows, Radarr manages movies; Jellyfin expects separate library roots for each type.

### raziel
Fingerprint: `libfprint` native — do NOT add `libfprint-2-tod1-goodix` (corrupts enrollment). `fprintd-enroll $USER` after first boot. `fprintAuth = true` for sudo + polkit (accepted tradeoff: laptop, physically attended).

**Charge-limit udev rule (`hosts/raziel/extra/laptop.nix`):** picks 80% (left port) / 100% (right port). User-session calls (`noctalia msg caffeine-enable/disable`, `notify-send`) are wrapped in a `run_user` helper that no-ops when `/run/user/1000/bus` doesn't exist — safe during early boot / no-login. Uses the absolute `/run/current-system/sw/bin/noctalia` (system package — see Noctalia section for why the binary is not HM-installed).

### Desktop session — niri (zaphkiel + raziel)
greetd + tuigreet → `niri-session`. niri 26.04 spawns `xwayland-satellite` itself off `$PATH` with its own listenfds, so the package stays in `parts/modules/niri.nix` but there is no HM unit; a hand-rolled one loses the race for `:0` and its `rm /tmp/.X11-unix/X0` unlinks the socket niri's Xwayland is serving. `XCURSOR_THEME`/`XCURSOR_SIZE` in the session env outrank Xresources, so no xrdb merge is needed. One global `layout {}` (noctalia owns it). No `is-only-window` in 26.04 — use `open-maximized true`.

### Noctalia (v5, native — `noctalia` binary, no Quickshell)
On v5.0.0 (input `noctalia` = repo `noctalia-shell`, but binary renamed `noctalia-shell`→`noctalia`). Launched via niri `spawn-at-startup "noctalia"`; **binary is a SYSTEM package** (`parts/modules/niri.nix`) so `/run/current-system/sw/bin/noctalia` stays valid for raziel's udev charge-limit rule + swayidle `before-sleep`.

**Two-layer config (the mutability story):**
- **Declarative base** → `~/.config/noctalia/config.toml`, Nix-owned via `home/noctalia.nix` (`programs.noctalia`, the **home-manager upstream** module -- do NOT also import `inputs.noctalia.homeModules.default`, duplicate option declaration breaks eval; the flake input is still used for the binary in `parts/modules/niri.nix`). Read-only symlink is fine.
- **Runtime state** → `~/.local/state/noctalia/settings.toml`, written by GUI/IPC. Load order = builtin defaults → config.toml → state, **merged PER-KEY, state wins**. GUI auto-prunes a state key when it matches the lower layer. ⇒ Nix is the base; state holds deviations.
- **Left mutable in state (NOT nixed):** `[theme]` (palette/mode), `[wallpaper]`, and the **monitor-coupled** layouts `[desktop_widgets]` + `[lockscreen_widgets]` (embed connector names like `HDMI-A-1` → per-host, would break raziel's `eDP-1`). **Nixed in config.toml:** `[backdrop]`, `[bar*]`, `[widget.*]`, `[control_center]`, `[dock]`, `[location]`, `[plugins]`, `[shell*]`, `[theme.templates]`. (`[bar*]`/`[widget.*]` carry no monitor names so they're portable — trade-off is bar tweaks need a rebuild, not a live GUI drag.)
- **Migration caveat:** after changing a nixed key you must remove it from state too (stale state shadows Nix). Done once via the `settings.toml.pretrim-*` trim; future nixed-key changes need the same.

**`home/noctalia.nix`:** `programs.noctalia = { enable = true; package = null; systemd.enable = false; settings = {…}; }`. `package = null` is deliberate — emits config.toml only, no double-install (binary is the system package above). `systemd.enable = false` — niri spawns it.

**Palettes:** whole-dir symlink `config/noctalia/palettes/` → `~/.config/noctalia/palettes/` (in `home/noctalia.nix`). 26 **dark-only** JSON files (each has only a `dark` block of `m*` roles + `terminal`; v5 derives light mode at runtime, so standalone light files were redundant and removed). Selected via `noctalia msg color-scheme-set custom <name>`; custom schemes show in the GUI picker. Add a theme = drop a `.json` + `git add` + rebuild.

**Templates** (`[theme.templates]` in config.toml):
- `builtin_ids` (btop, gtk3/4, ghostty, kcolorscheme, niri, qt, starship) + `community_ids` (neovim, vscode, discord, yazi).
- **Community templates** are fetched from `api.noctalia.dev` and cached in `~/.local/state/noctalia/community-templates/`. **`offline_mode = true` blocks the fetch** — symptom is `[theme_templates] community template 'x' is not cached yet` + un-themed apps. Turn offline off, then `config-reload`.
- **fcitx5** has no community template → declared **inline** as `[theme.templates.user.fcitx5]` (input = `config/noctalia/templates/fcitx5-theme.conf` symlink, output = `~/.local/share/fcitx5/themes/noctalia/theme.conf`, `post_hook` restarts fcitx5). Inline user templates apply with no GUI toggle — this **replaces** the legacy `user-templates.toml` + "User templates" toggle (both removed). nvim is community-managed (community `neovim` + custom would both write `nvim/lua/matugen.lua` → don't redefine).

**IPC** is `noctalia msg <command>` (v4 was `noctalia-shell ipc call <t> <a>`): `panel-toggle <id>` (launcher/clipboard/session/wallpaper/control-center), `settings-toggle`, `session lock|suspend|…`, `caffeine-enable|disable`, `screenshot-region`, `config-reload`, `color-scheme-set/get`. Keybinds in `config/niri/keybinds.kdl`.

**niri overview backdrop:** `config/niri/noctalia.kdl` has `layer-rule { match namespace="^noctalia-backdrop"; place-within-backdrop true }` (v5 renamed the surface from `noctalia-overview`) + `[backdrop] enabled` — wallpaper shows in overview (`Mod+grave`).

**Monitor coupling:** only `[wallpaper.monitors.*]` + `[lockscreen_widgets]` name connectors (HDMI-A-1/2). Login boxes auto-regenerate per output; decorative lockscreen widgets use literal `output =` + absolute `cx`/`cy` (per-resolution) — inherently per-host, hence left in state (would break raziel's `eDP-1`). Stale v4 `~/.config/noctalia/settings.json` (JSON) is ignored by v5 — safe to delete.

- Starship: do NOT pre-populate `[palettes.noctalia]` (duplicate TOML key on theme change). Do NOT use `programs.starship` (read-only symlink).
- VSCodium: noctalia extension as writable copy via `home.activation` — NOT in extensions list.
- GTK: NOT managed by HM `gtk` module — uses `adw-gtk3` + dconf in `home/qt.nix`.
- **Maple Mono weight gotcha:** non-standard weights register as separate fc families, not weight variants.
- **ONLYOFFICE fonts:** ignores symlinks — copy real files via `home.activation`; include `*.ttc` for CJK.

**Noctalia pending polish (non-blocking, from the v4→v5 migration):**
- **niri `include`:** `niri` is a builtin template, so v5 wants to append `include "noctalia.kdl"` to `~/.config/niri/config.kdl` — but that's a read-only HM symlink that currently *inlines* a static `config/niri/noctalia.kdl` (which itself `include`s a writable `~/.config/niri/noctalia.kdl` placeholder from `home/desktop/niri.nix`). Works (backdrop namespace already fixed to `^noctalia-backdrop`), logs a non-fatal permission warning on theme apply. Cleaner end-state: emit `include "noctalia.kdl"` from `niri.nix` and drop the static `noctalia.kdl` from `niriParts`.
- **starship marker:** `home/programs/starship.nix` preserves everything from a single `# >>> NOCTALIA STARSHIP PALETTE >>>` marker to EOF. If v5 ever switches to a bounded begin/end block, this needs updating. (The noctalia-off static-`[palettes.fallback]` branch is already wired.)
- **VSCodium:** the community `vscode` template writes into the `noctalia.noctaliatheme` extension dir, which `home/programs/vscodium.nix` keeps mutable via `home.activation` — verify they don't fight on a theme change.

### Shell
`reload = "exec zsh"`. `init-shell` `.envrc` must be ONLY `use flake` — any extra export causes infinite direnv reload loop. `exec zsh` in shellHook must be guarded by `[[ $- == *i* ]]`.

### Users / Auth / Secrets
- `users.mutableUsers = false`. Passwords: `mkpasswd --method=yescrypt`.
- `parts/universal/users.nix` currently ships `hashedPassword` inline for `kuroma` and `root`. Repo is push-mirrored to public GitHub via Forgejo — these hashes are public. Acceptable only if the password is unique to this host and high-entropy; otherwise migrate to `hashedPasswordFile` from sops. (Migration TODO also noted under Pending work.)
- Sops: `nix-shell -p sops --run 'sops secrets/secrets.yaml'`. New host: add SSH host key to `.sops.yaml` after first boot.
- **World-readable secrets (`mode = "0444"`):** `nut/monitor-password` (local-only impact), `forgejo/runner-token` (registration only). `cloudflared/token` and `vaultwarden/smtp-password` should ideally have proper owners — DynamicUser blocks that for cloudflared without restructuring.

## Pending work
- **Vault-Storage ext4 → btrfs migration:** plan documented in `PLAN.md`. Waiting on current arxiv rsync to metatron to finish before starting.
- **`hashedPasswordFile` migration** for kuroma/root in `parts/universal/users.nix` (if/when convenient).
- **Post-refactor switch on zaphkiel** still pending (host offline as of 2026-06-01). See verification procedure below; delete this bullet once switched.

## Post-refactor verification (temporary)

The big tier/options refactor (commit range `62bee79..HEAD`) landed without changing any package — only generated configs/units differ. Procedure for cutover on a host that wasn't switched yet:

1. **Build, don't switch:**
   ```
   cd ~/System/nixos-configs
   sudo nixos-rebuild build --flake .#<host>
   ```
2. **Diff the closure** (should list small text-substitution drvs only; no new packages):
   ```
   nix store diff-closures /run/current-system $(readlink -f result)
   ```
   Expected on **zaphkiel**: caddy config, llama-router unit, polkit, dbus-broker, generated `etc`/`system-path`/`system-units`/`user-units`/`activate` aggregators. No CUDA / OBS / cc1plus compiles. If you see source builds, stop and investigate.

3. **Dry-activate** to see exactly what would stop/restart/reload:
   ```
   sudo result/bin/switch-to-configuration dry-activate
   ```
   Expected on **zaphkiel**:
   - **Reload (no traffic interruption):** caddy, dbus-broker
   - **Restart (~1s gap):** polkit, llama-router (llama-embedding is removed — it should stop, not restart)
   - **Untouched:** sshd, jellyfin, navidrome, postgresql, syncthing, n8n, neo4j, sonarr, radarr
   - `syncthing/password` secret is **kept** on zaphkiel (it's enabled there — only removed from metatron, which never used it)

4. **Switch:**
   ```
   sudo nixos-rebuild switch --flake .#<host>
   ```
5. **Spot-check:**
   - `systemctl status caddy` (active, reloaded)
   - `systemctl status llama-router` (active)
   - For metatron only: `systemctl status cloudflared-main` (the rename — new unit must come up; old `cloudflared` is gone). `wantedBy=multi-user.target` triggers it via target re-evaluation; if it doesn't start, `sudo systemctl start cloudflared-main`.

**Metatron switched on 2026-06-01.** Verified: cloudflared rename was the only behavior change; CF-fronted sites stayed reachable across the switch.

## Misc gotchas
- **Vaultwarden `ProtectSystem=strict`:** add `ReadWritePaths = [ "/tank/services/vaultwarden" ]` or exits with EROFS.
- **Hibernate resume:** zaphkiel/raziel: `boot.resumeDevice = "/dev/mapper/cryptroot"` + `resume_offset` from `btrfs inspect-internal map-swapfile -r /swap/swapfile`. metatron: `/dev/nvme0n1p2`. NVIDIA needs `powerManagement.enable + NVreg_PreserveVideoMemoryAllocations=1`. **zaphkiel ZFS:** `zfs-export-vault-pre-hibernate.service` exports `vault` before the hibernate image is written — without it ZFS sees a dirty pool on resume and either refuses import or corrupts.
- **MPV:** use `nvdec-copy` not `nvdec`. `osc = "no"` (thumbnail scripts replace OSC).
- **Dolphin "Open With" empty:** `kbuildsycoca6` oneshot must run at session start.
- **Nextcloud fresh install recovery:** drop+recreate DB, delete `config.php` and `data/` if `nextcloud-setup` fails mid-install.
- **State versions:** all hosts `stateVersion = "25.11"`. Do not bump.
