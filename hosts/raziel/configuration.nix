{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix

    ../../parts/universal
    ../../parts/templates
    ../../parts/modules
    ../../parts/services

    ./extra
  ];

  networking.hostName = "raziel";

  host = {
    gpu.amd = true;
    desktop = "niri";
    profile = "desktop";
    features = {
      autofs = true;
      virtualization = true;
    };

    services = {
      syncthing = { enable = true; port = 8384; };
      cockpit   = { enable = true; port = 9090; };
    };
  };

  boot.kernelParams = [
    # s2idle suspend — recommended for Framework 13 AMD
    "mem_sleep_default=s2idle"
    "resume_offset=533760"
    "resume=/dev/mapper/cryptroot"
  ];

  system.stateVersion = "25.11";
}
