{ pkgs, inputs, config, lib, ... }:
lib.mkIf (config.host.profile == "desktop") {
  services.envfs.enable = true; # symlinks /bin stuff to scripts

  # millenium steam for custom colors
  programs.steam = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    xterm
    glfw
  ];
}
