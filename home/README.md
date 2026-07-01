# home/

home-manager, one concern per file, tiered like `parts/`. Every host imports `./home` as its single HM entry (the flake never inlines HM).

**The machine's HM tickbox is `host.home.*`** — declared in `parts/templates/home.nix`, set per host in `configuration.nix`, read here via `osConfig`. Bundles default to follow `host.profile` (`server` | `desktop`); a host unticks what it doesn't want.

```text
home/
├── default.nix     # single entry. imports base always; dev when host.home.dev (any profile);
│                   #   the graphical layers only when host.profile == "desktop".
├── base/           # headless-safe, imported by EVERY host (git, zsh, nushell).
├── dev/            # headless-safe dev tooling, gated by host.home.dev (servers included).
│                   #   nvim + packages. Must not need a graphical session.
├── programs/       # one file per graphical program (enable + config). desktop-only.
├── desktop/        # session/DE integration (niri, noctalia, theming, mimeapps, kde). desktop-only.
├── packages.nix    # the install-only package list. desktop-only.
├── fonts.nix       # rice.fonts option + font deployment.
└── scripts/        # authored shell-script packages.
```

**Gating idiom:** the *tier import* is the gate — files inside `dev/` don't re-check `host.home.dev`. Bundle-specific program files self-gate with `lib.mkIf osConfig.host.home.<bundle>` (mpv→media, vscodium→dev), exactly like a `parts/services/*` gates on its `enable`.

**Static files** → `config/`, pulled in via `.source` from the owning module (`base/` if headless-safe, else `programs/`/`desktop/`). Never write NF icons or ANSI escapes in Nix strings.

**noctalia routing:** modules that *require* noctalia's runtime-generated files branch on `osConfig.host.home.noctalia` and carry a static fallback (nvim, starship). See `CLAUDE.md` for the full mutability story.
