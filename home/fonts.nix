{ lib, config, ... }:
{
  options.rice.fonts = {
    ui   = lib.mkOption { type = lib.types.str; default = "Google Sans Flex"; };
    mono = lib.mkOption { type = lib.types.str; default = "Google Sans Code"; };
  };

  config = {
    xdg.dataFile."fonts/GoogleSansFlex-VariableFont.ttf".source =
      ../config/fonts/GoogleSansFlex-VariableFont.ttf;

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
