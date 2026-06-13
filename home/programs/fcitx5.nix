{ config, ... }:
{
  # classicui.conf: font from rice.fonts, theme written by noctalia at runtime.
  # Language/input-group config is managed manually (fcitx5 rewrites it on exit).
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Font=${config.rice.fonts.ui} ${toString config.rice.fonts.uiSize}
    Theme=noctalia
    PerScreenDPI=True
    Vertical Candidate List=False
    WheelForPaging=True
    EnableWaylandIM=True
  '';
}
