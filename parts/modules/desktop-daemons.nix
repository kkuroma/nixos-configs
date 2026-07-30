{ config, lib, ... }:
# Desktop-session daemon bundle (bluetooth, audio, printing, power, removable media):
# everything a graphical session needs and no server does. sshd is universal; snapper is ./snapper.nix.
lib.mkIf (config.host.profile == "desktop") {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.udisks2.enable = true;
  services.printing.enable = true;
  services.power-profiles-daemon.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
}
