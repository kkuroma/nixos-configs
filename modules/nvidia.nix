{ config, ... }:
{
  nixpkgs.config.cudaSupport = true;

  # Required for Xwayland to use the NVIDIA GLX implementation instead of Mesa's.
  # Without this, OpenGL apps (including Java games via Prism Launcher) run on
  # llvmpipe / wrong-GPU and get <10% of expected performance.
  environment.variables.__GLX_VENDOR_LIBRARY_NAME = "nvidia";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  hardware.nvidia-container-toolkit.enable = true;

  services.lact.enable = true;
}
