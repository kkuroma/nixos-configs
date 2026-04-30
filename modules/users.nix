{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  users.users.kuroma = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    initialPassword = "temp";
  };

  security.sudo.wheelNeedsPassword = true;
}
