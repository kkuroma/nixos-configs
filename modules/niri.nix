{ pkgs, inputs, ... }:
{
  programs.niri.enable = true;
  programs.dconf.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --cmd niri-session";
        user = "greeter";
      };
      initial_session = {
        command = "niri-session";
        user = "kuroma";
      };
    };
  };

  environment.variables = {
    XCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "breeze_cursors";
    HYPRCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    # Ensures Qt apps wrapped by nixpkgs can find the qt6ct platform theme plugin
    QT_PLUGIN_PATH = "/run/current-system/sw/lib/qt-6/plugins";
  };

  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.xwayland-satellite
    pkgs.wl-clipboard
    pkgs.papirus-icon-theme
    pkgs.kdePackages.breeze
    pkgs.qt6Packages.qt6ct
    pkgs.adwaita-qt6
  ];
}
