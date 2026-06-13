{ config, pkgs, ... }:
let
  imvCopy = pkgs.writeShellScript "imv-copy" ''
    cat "$1" | ${pkgs.wl-clipboard}/bin/wl-copy
    ${pkgs.libnotify}/bin/notify-send -a "System" "Image Copied" "Copied $1 to clipboard" -i preferences-desktop
  '';
in
{
  xdg.configFile."imv/config".text = ''
    [options]
    overlay = true
    overlay_font = ${config.rice.fonts.ui}:${toString config.rice.fonts.uiSize}
    overlay_text = [$imv_current_index/$imv_file_count] [ESC: Quit] [Ctrl-C: Copy Path] [$imv_width x $imv_height] $imv_scale% $(basename "$imv_current_file")

    [binds]
    <Ctrl+c> = exec ${imvCopy} "$imv_current_file"
    <Escape> = quit
  '';
}
