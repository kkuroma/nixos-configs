{ pkgs, ... }:
{
  # Minimal applications.menu required by kbuildsycoca6 to build its application service db
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultMergeDirs/>
    </Menu>
  '';

  # Rebuild KDE's service database once per graphical session so dolphin has a "open with" dialog
  systemd.user.services.kbuildsycoca6 = {
    Unit = {
      Description = "Rebuild KDE service configuration cache";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
