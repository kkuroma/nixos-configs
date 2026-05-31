{ lib, ... }:

# Blind-import every services/*.nix. Each service file is gated on
# `host.services.<name>.enable`, so files for disabled services emit nothing.
# Add a service: drop a file here + flip its switch in the host.

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
