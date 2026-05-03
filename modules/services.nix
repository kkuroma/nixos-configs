{ ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;
  services.openssh.enable = true;
  services.printing.enable = true;
  services.tailscale.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.syncthing = {
    enable = true;
    user = "kuroma";
    dataDir = "/home/kuroma";
    settings.folders."Documents" = {
      path = "/home/kuroma/Documents";
    };
  };
}
