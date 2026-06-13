{ lib, ... }:

# Blind-import every desktop/*.nix. Session / desktop-environment integration that
# isn't a single CLI app: compositor (niri), shell (noctalia), Qt/GTK theming, xdg
# mime associations, KDE service menus, etc. Add a concern: drop a file here.

let
  here = builtins.readDir ./.;
  isNixFile = name: type:
    type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  nixFiles = lib.filterAttrs isNixFile here;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") nixFiles;
}
