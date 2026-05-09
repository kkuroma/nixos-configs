{ lib, config, pkgs, ... }:
{
  options.rice.fonts = {
    ui = lib.mkOption { type = lib.types.str; default = "Google Sans Flex"; };
    mono = lib.mkOption { type = lib.types.str; default = "Maple Mono NF CN"; };
    uiSize = lib.mkOption { type = lib.types.int; default = 12; };
    monoSize = lib.mkOption { type = lib.types.int; default = 12; };
  };

  config = {
    xdg.dataFile."fonts/GoogleSansFlex-VariableFont.ttf".source = ../config/fonts/GoogleSansFlex-VariableFont.ttf;

    # ONLYOFFICE's font picker ignores symlinks — only real file copies are scanned.
    # Copy Noto fonts into ~/.local/share/fonts/onlyoffice/ so they appear in the picker.
    # Sentinel files prevent redundant copies across rebuilds; cache is cleared to force rescan.
    home.activation.onlyofficeFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dest="$HOME/.local/share/fonts/onlyoffice"
      mkdir -p "$dest"
      stale=0

      sentinel="$dest/.noto-sentinel"
      if [ "$(cat "$sentinel" 2>/dev/null)" != "${pkgs.noto-fonts}" ]; then
        find ${pkgs.noto-fonts}/share/fonts \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$dest/" \;
        printf '%s' "${pkgs.noto-fonts}" > "$sentinel"
        stale=1
      fi

      sentinel_cjk="$dest/.noto-cjk-sentinel"
      if [ "$(cat "$sentinel_cjk" 2>/dev/null)" != "${pkgs.noto-fonts-cjk-sans}" ]; then
        find ${pkgs.noto-fonts-cjk-sans}/share/fonts \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) -exec cp -f {} "$dest/" \;
        printf '%s' "${pkgs.noto-fonts-cjk-sans}" > "$sentinel_cjk"
        stale=1
      fi

      sentinel_maple="$dest/.maple-sentinel"
      if [ "$(cat "$sentinel_maple" 2>/dev/null)" != "${pkgs.maple-mono.NF-CN}" ]; then
        find ${pkgs.maple-mono.NF-CN}/share/fonts \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$dest/" \;
        printf '%s' "${pkgs.maple-mono.NF-CN}" > "$sentinel_maple"
        stale=1
      fi

      sentinel_jbm="$dest/.jetbrains-sentinel"
      if [ "$(cat "$sentinel_jbm" 2>/dev/null)" != "${pkgs.nerd-fonts.jetbrains-mono}" ]; then
        find ${pkgs.nerd-fonts.jetbrains-mono}/share/fonts \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$dest/" \;
        printf '%s' "${pkgs.nerd-fonts.jetbrains-mono}" > "$sentinel_jbm"
        stale=1
      fi

      # Google Sans Flex is deployed as a symlink via xdg.dataFile; copy the real file for ONLYOFFICE's scanner
      gsf_src="${../config/fonts/GoogleSansFlex-VariableFont.ttf}"
      if [ "$(cat "$dest/.gsf-sentinel" 2>/dev/null)" != "$gsf_src" ]; then
        cp -f "$gsf_src" "$dest/GoogleSansFlex-VariableFont.ttf"
        printf '%s' "$gsf_src" > "$dest/.gsf-sentinel"
        stale=1
      fi

      if [ "$stale" = "1" ]; then
        rm -f "$HOME/.local/share/onlyoffice/desktopeditors/data/fonts/fonts.log"
        rm -f "$HOME/.local/share/onlyoffice/desktopeditors/data/fonts/font_selection.bin"
      fi
    '';
    xdg.configFile."fontconfig/fonts.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <alias>
          <family>sans-serif</family>
          <prefer>
            <family>${config.rice.fonts.ui}</family>
            <family>Noto Sans CJK JP</family>
            <family>Noto Sans CJK SC</family>
            <family>Noto Sans CJK KR</family>
            <family>Noto Sans Arabic</family>
            <family>Noto Sans Thai</family>
            <family>Noto Sans Hebrew</family>
            <family>Noto Sans Devanagari</family>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
        <alias>
          <family>serif</family>
          <prefer>
            <family>Noto Serif</family>
            <family>Noto Serif CJK JP</family>
            <family>Noto Serif CJK SC</family>
            <family>Noto Serif CJK KR</family>
          </prefer>
        </alias>
        <alias>
          <family>monospace</family>
          <prefer>
            <family>${config.rice.fonts.mono}</family>
            <family>Noto Sans Mono CJK JP</family>
            <family>Noto Sans Mono CJK SC</family>
            <family>Noto Sans Mono CJK KR</family>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
      </fontconfig>
    '';
  };
}
