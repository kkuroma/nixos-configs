{ lib, niriParts, ... }:
{
  xdg.configFile."niri/config.kdl".text =
    lib.concatMapStrings builtins.readFile niriParts;
  home.activation.niriNoctaliaFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.config/niri/noctalia.kdl" ]; then
      echo "// placeholder — noctalia will overwrite this on first run" \
        > "$HOME/.config/niri/noctalia.kdl"
    fi
  '';
}
