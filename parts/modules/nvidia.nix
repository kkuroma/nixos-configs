{ config, lib, ... }:
lib.mkIf config.host.gpu.nvidia {
  nixpkgs.config.cudaSupport = true;

  # onnxruntime without nvidia so shit doesnt compile each time i just want to update
  nixpkgs.overlays = [ (final: prev: {
    onnxruntime = prev.onnxruntime.override { cudaSupport = false; };
  }) ];

  # Required for Xwayland to use the NVIDIA GLX implementation instead of Mesa's.
  # Without this, OpenGL apps (including Java games via Prism Launcher) run on
  # llvmpipe / wrong-GPU and get <10% of expected performance.
  environment.variables.__GLX_VENDOR_LIBRARY_NAME = "nvidia";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Required to make nvidia hibernation possible
  boot.extraModprobeConfig = "options nvidia NVreg_PreserveVideoMemoryAllocations=1";
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  hardware.nvidia-container-toolkit.enable = true;

  services.lact.enable = true;
}
