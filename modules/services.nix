{ ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;  # key-only auth
      PermitRootLogin = "no";
    };
  };

  services.printing.enable = true;

  services.power-profiles-daemon.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
