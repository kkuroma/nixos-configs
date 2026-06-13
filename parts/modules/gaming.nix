{ pkgs, config, lib, ... }:
# System half of the gaming bundle. host.home.gaming (parts/templates/home.nix) is read
# both here (system: the Steam stack) and by HM (osu/prismlauncher/gamescope) — one tickbox.
lib.mkIf config.host.home.gaming {
  # millenium steam for custom colors
  programs.steam.enable = true;

  # let Steam/Proton run foreign, dynamically-linked binaries (/bin, /usr/bin shims)
  services.envfs.enable = true;

  environment.systemPackages = with pkgs; [
    xterm # fallback terminal some game launchers/installers spawn
    glfw # OpenGL window/input runtime dep
  ];
}
