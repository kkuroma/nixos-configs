{ config, lib, ... }:
{
  programs.zathura = {
    enable = true;
    options = {
      font = "${config.rice.fonts.ui} ${toString config.rice.fonts.uiSize}";
      recolor = false;
      scroll-step = 80;
      zoom-min = 10;
      zoom-max = 1000;
      guioptions = "sv";
    };
    extraConfig = "include ${config.xdg.configHome}/zathura/noctaliarc";
  };

  # Fallback noctaliarc so zathura's include doesn't fail before noctalia (community
  # 'zathura' template) writes the themed file on first color-scheme apply.
  home.activation.zathuraNoctaliarcFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/zathura/noctaliarc" ]; then
      mkdir -p "$HOME/.config/zathura"
      echo "# placeholder — noctalia will overwrite this" \
        > "$HOME/.config/zathura/noctaliarc"
    fi
  '';
}
