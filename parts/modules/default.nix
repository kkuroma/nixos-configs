{ lib, ... }:

# Tier 2/3: opt-in modules. Each file gates on an option declared in
# templates/system.nix (host.gpu.*, host.desktop, host.profile,
# host.features.*). Universal modules live in ../universal/.

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
