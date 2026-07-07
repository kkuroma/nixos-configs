{ config, lib, pkgs, ... }:
# AntiMicroX (gamepad → keyboard/mouse) + generic USB controller support.
lib.mkIf config.host.features.controller {
  environment.systemPackages = [ pkgs.antimicrox ];

  hardware.uinput.enable = true;        # AntiMicroX synthesizes input via /dev/uinput
  hardware.steam-hardware.enable = true; # udev rules for ~every mainstream controller

  services.udev.extraRules = ''
    SUBSYSTEM=="input", GROUP="input", TAG+="uaccess"
    KERNEL=="js[0-9]*", GROUP="input", TAG+="uaccess"
    KERNEL=="uinput", GROUP="input", TAG+="uaccess", OPTIONS+="static_node=uinput"
  '';
}
