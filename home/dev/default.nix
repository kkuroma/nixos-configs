# Headless-safe dev tooling, imported whenever host.home.dev (servers included).
# Nothing here may require a graphical session; noctalia-themed modules need a static fallback.
{ imports = import ../../lib/import-dir.nix ./.; }
