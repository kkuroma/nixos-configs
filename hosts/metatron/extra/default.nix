{ lib, ... }:
let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
