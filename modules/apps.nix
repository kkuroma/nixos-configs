{ pkgs, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    dolphin
    kdenlive
    obs-studio
    vesktop
    prismlauncher
    ffmpeg
  ];
}
