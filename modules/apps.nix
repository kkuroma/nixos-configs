{ pkgs, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kdenlive
    obs-studio
    vesktop
    prismlauncher
    ffmpeg
  ];
}
