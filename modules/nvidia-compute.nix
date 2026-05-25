{ ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = false;
    open = false; # GTX 1650: proprietary driver
    nvidiaSettings = false;
    powerManagement.enable = false;
  };
}
