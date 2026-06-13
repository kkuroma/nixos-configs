{ lib, ... }:

# Blind-import every programs/*.nix. One file per configured program; each does
# `programs.<name>.enable` (which installs it) + its config. Install-only packages
# live in home/packages.nix, not here. Add a configured app: drop a file here.

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
