{ pkgs, ... }:
let
  # plasma-workspace's other kded plugins autoload and would claim noctalia's tray
  kdedPlugins = pkgs.symlinkJoin {
    name = "kded-plugins-soliduiserver";
    paths = [ pkgs.kdePackages.qtwayland ];
    postBuild = ''
      mkdir -p $out/lib/qt-6/plugins/kf6/kded
      ln -s ${pkgs.kdePackages.plasma-workspace}/lib/qt-6/plugins/kf6/kded/soliduiserver.so \
        $out/lib/qt-6/plugins/kf6/kded/
    '';
  };
in
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

  # Solid hands LUKS passphrase prompts to plasma's SolidUiServer, which kded6 hosts
  systemd.user.services.kded6 = {
    Unit = {
      Description = "KDE Daemon 6";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.kde.kded6";
      Environment = [ "QT_PLUGIN_PATH=${kdedPlugins}/lib/qt-6/plugins" ];
      ExecStart = "${pkgs.kdePackages.kded}/bin/kded6";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
