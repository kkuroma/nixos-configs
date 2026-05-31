{ pkgs, lib, config, ... }:
lib.mkIf (config.host.profile == "desktop") {
  fonts.packages = with pkgs; [
    maple-mono.NF-CN
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    google-fonts
    nerd-fonts.jetbrains-mono
  ];

  # fallbacks in case the userspace font cant be found
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    monospace = [ "Noto Sans Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };

  fonts.fontDir.enable = true;
}
