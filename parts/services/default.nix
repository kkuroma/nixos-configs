{ lib, ... }:

# Tier 3: blind-import every services/*.nix (each self-gates on host.services.<name>.enable).
# Filenames register the valid host.services keys — the file name IS the option key.
let
  files = import ../../lib/import-dir.nix ./.;
in
{
  imports = files;
  host.knownServices = map (f: lib.removeSuffix ".nix" (baseNameOf f)) files;
}
