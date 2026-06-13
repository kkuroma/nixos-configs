{ lib, ... }:

# Headless-safe dev tooling, imported whenever `host.home.dev` (any profile — works on
# servers). Modules here must not require a graphical session or noctalia; anything that
# theming-routes through noctalia carries a static fallback for the noctalia-off case.

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
