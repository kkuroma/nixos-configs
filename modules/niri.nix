{ pkgs, inputs, ... }:
{
  programs.niri.enable = true;

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
  };

  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.xwayland-satellite
    pkgs.wl-clipboard
    pkgs.papirus-icon-theme
    pkgs.kdePackages.breeze
  ];
}
