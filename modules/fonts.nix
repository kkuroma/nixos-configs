{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    maple-mono.NF
    noto-fonts
    noto-fonts-cjk-sans
    gabarito
    nerd-fonts.jetbrains-mono
  ];
}
