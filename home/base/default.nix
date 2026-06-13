{ lib, ... }:

# Headless-safe HM modules imported by EVERY host (desktop + server). Keep this dir
# free of anything that needs a graphical session — those go in home/programs/ or
# home/desktop/, which only the desktop entry imports.

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
