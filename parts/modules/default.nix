# Tier 2: opt-in modules, each gated on an option from templates/system.nix or templates/home.nix.
{ imports = import ../../lib/import-dir.nix ./.; }
