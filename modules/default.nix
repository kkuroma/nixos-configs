{ lib, ... }:

# Blind-import every modules/*.nix. Universal modules (boot, locale,
# networking, nix, sops, users, caddy) emit unconditionally. Switchable
# ones gate on options declared in templates/system.nix:
#   host.gpu.{amd,nvidia,nvidiaCompute}, host.desktop, host.profile,
#   host.features.{autofs,virtualization,codiumserver}

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
