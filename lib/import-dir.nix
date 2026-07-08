# Blind-import helper: every *.nix in a directory except default.nix.
# Usage from a default.nix:  { imports = import ../../lib/import-dir.nix ./.; }
dir:
let
  entries = builtins.readDir dir;
  isNixFile = name:
    entries.${name} == "regular"
    && name != "default.nix"
    && builtins.match ".*\\.nix" name != null;
in
map (name: dir + "/${name}") (builtins.filter isNixFile (builtins.attrNames entries))
