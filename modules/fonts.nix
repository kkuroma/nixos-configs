{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    maple-mono.NF-CN      # includes CJK glyphs — replaces NF variant
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    google-fonts
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    monospace = [ "Noto Sans Mono" ];
    emoji    = [ "Noto Color Emoji" ];
  };
}
