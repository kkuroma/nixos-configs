{ config, inputs, lib, osConfig, pkgs, ... }:
let
  # prepends /usr/bin at launch because glycun (GTK4 image loader) expects it
  bambuLauncher = pkgs.writeShellScript "bambustudio-launch" ''
    export PATH=/usr/bin:$PATH
    exec flatpak run --branch=stable --arch=x86_64 --command=entrypoint --file-forwarding com.bambulab.BambuStudio @@u "$@" @@
  '';
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  config = lib.mkIf osConfig.host.home."3d-printing" {
    services.flatpak = {
      update.onActivation = true;
      packages = [ "com.bambulab.BambuStudio" ];
    };

    # Expose flatpak app .desktop entries to the launcher
    systemd.user.sessionVariables.XDG_DATA_DIRS =
      "${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:\${XDG_DATA_DIRS}";

    # Override the flatpak-exported entry, ritten into XDG_DATA_HOME (~/.local/share), so launchers can see it
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
