{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    maple-mono.NF
    noto-fonts
    noto-fonts-cjk-sans
    google-fonts
    nerd-fonts.jetbrains-mono
  ];
}
