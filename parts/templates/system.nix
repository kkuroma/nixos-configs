{ config, lib, ... }:
{
  # A "desktop" profile pulls in the graphical HM layers, which presume a session.
  config.assertions = [{
    assertion = config.host.profile == "desktop" -> config.host.desktop != null;
    message = ''host.profile = "desktop" requires host.desktop to be set (niri/kde).'';
  }];

  options.host = {
    gpu = {
      amd           = lib.mkEnableOption "AMD graphics + amd_pstate=active";
      nvidia        = lib.mkEnableOption "NVIDIA proprietary display (open kernel)";
      nvidiaCompute = lib.mkEnableOption "NVIDIA headless CUDA";
    };

    desktop = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "niri" "kde" ]);
      default = null;
      description = "Desktop environment to enable.";
    };

    profile = lib.mkOption {
      type = lib.types.enum [ "server" "desktop" ];
      default = "server";
      description = "desktop = enable apps/fonts/fcitx5/desktop daemon bundle.";
    };

    features = {
      autofs         = lib.mkEnableOption "autofs CIFS mounts from metatron";
      virtualization = lib.mkEnableOption "docker + libvirt + podman";
      codiumserver   = lib.mkEnableOption "VSCodium remote server";
      yubikey        = lib.mkEnableOption "YubiKey tooling (ykman, pcscd, udev rules)";
      controller     = lib.mkEnableOption "AntiMicroX + generic USB game controller support";
    };
  };
}
