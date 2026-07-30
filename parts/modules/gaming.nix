{ pkgs, config, lib, ... }:
# System half of the gaming bundle
lib.mkIf config.host.home.gaming {
  programs.steam.enable = true;
  services.envfs.enable = true; # enable foreign dynamically linked variabes (/bin, /usr/bin stuff)
  hardware.xpadneo.enable = true; # enable controller bt support for XBox controllers
  boot.extraModprobeConfig = ''options btusb enable_autosuspend=0 '';
  environment.systemPackages = with pkgs; [
    xterm # fallback terminal some game launchers/installers spawn
    glfw # OpenGL window/input runtime dep
  ];
}
