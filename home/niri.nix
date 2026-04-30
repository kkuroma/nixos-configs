{ lib, niriParts, ... }:
{
  xdg.configFile."niri/config.kdl".text =
    lib.concatMapStrings builtins.readFile niriParts;
}
