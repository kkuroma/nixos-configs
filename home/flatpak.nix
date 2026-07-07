{ config, inputs, lib, osConfig, pkgs, ... }:
# Declarative user flatpaks from Flathub. Runtime enabled in parts/modules/flatpak.nix.
let
  # glycin (GTK4 image loader) decodes icons in a nested `flatpak-spawn --sandbox` that
  # inherits the launch PATH and runs `prlimit` bare — on NixOS that PATH lacks /usr/bin
  # so it fails and BambuStudio crashes. This wrapper prepends /usr/bin at launch (the one
  # spot the shell/systemd don't rebuild). `@@u "$@" @@` keeps flatpak file-forwarding.
  bambuLauncher = pkgs.writeShellScript "bambustudio-launch" ''
    export PATH=/usr/bin:$PATH
    exec flatpak run --branch=stable --arch=x86_64 --command=entrypoint --file-forwarding com.bambulab.BambuStudio @@u "$@" @@
  '';
in
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

    # Override the flatpak-exported entry so the launcher runs the /usr/bin wrapper above.
    # Written into XDG_DATA_HOME (~/.local/share), which is always resolved before any
    # XDG_DATA_DIRS entry — including the flatpak exports dir prepended above. (xdg.desktop-
    # Entries lands in the profile, which loses to the flatpak export, so it's not used.)
    xdg.dataFile."applications/com.bambulab.BambuStudio.desktop".text = ''
      [Desktop Entry]
      Name=BambuStudio
      GenericName=3D Printing Software
      Icon=com.bambulab.BambuStudio
      Exec=${bambuLauncher} %U
      Terminal=false
      Type=Application
      MimeType=model/stl;model/3mf;application/vnd.ms-3mfdocument;application/prs.wavefront-obj;application/x-amf;x-scheme-handler/bambustudio;model/step;
      Categories=Graphics;3DGraphics;Engineering;
      Keywords=3D;Printing;Slicer;slice;3D;printer;convert;gcode;stl;obj;amf;SLA
      StartupNotify=false
      StartupWMClass=bambu-studio
      X-Flatpak=com.bambulab.BambuStudio
    '';
  };
}
