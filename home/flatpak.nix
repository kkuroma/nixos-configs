{ config, inputs, lib, osConfig, ... }:
# Declarative user flatpaks from Flathub. Runtime enabled in parts/modules/flatpak.nix.
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  config = lib.mkIf osConfig.host.home.flatpak {
    services.flatpak = {
      update.onActivation = true;
      packages = [ "com.bambulab.BambuStudio" ];
    };

    # Expose flatpak app .desktop entries to the launcher.
    systemd.user.sessionVariables.XDG_DATA_DIRS =
      "${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:\${XDG_DATA_DIRS}";
  };
}
