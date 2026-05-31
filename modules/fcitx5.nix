{ pkgs, config, lib, ... }:
lib.mkIf (config.host.profile == "desktop") {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-chinese-addons
      fcitx5-m17n
    ];
  };
}
