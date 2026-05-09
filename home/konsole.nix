{ config, pkgs, lib, ... }:
{
  home.packages = [ pkgs.kdePackages.konsole ];

  # Deploy the profile file to ~/.local/share/konsole/
  xdg.dataFile."konsole/default.profile".text = ''
    [Appearance]
    AntiAliasFonts=true
    BoldIntense=false
    Font=${config.rice.fonts.mono},${toString config.rice.fonts.monoSize},-1,5,400,0,0,0,0,0,Regular

    [Scrolling]
    HistorySize=10000
    ScrollBarPosition=2

    [General]
    Name=default
    Parent=FALLBACK/
  '';

  # Use kwriteconfig6 to set keys without overwriting user-managed settings.
  home.activation.konsoleConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file $HOME/.config/konsolerc"
    $cfg --group "Desktop Entry" --key "DefaultProfile" "default.profile"
    $cfg --group "KonsoleWindow" --key "RememberWindowSize" "false"
    $cfg --group "KonsoleWindow" --key "ShowMenuBarByDefault" "false"
  '';
}
