{ pkgs, inputs, username, config, lib, ... }:
lib.mkIf (config.host.desktop == "niri") {
  programs.niri.enable = true;
  programs.dconf.enable = true;
  programs.uwsm.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --cmd niri-session";
        user = "greeter";
      };
      initial_session = {
        command = "niri-session";
        user = username;
      };
    };
  };

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.xwayland-satellite
    pkgs.xrdb
  ];
}
