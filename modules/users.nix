{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  users.users.kuroma = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... kuroma@laptop"  # add after generating laptop key
    ];
  };


  security.sudo.wheelNeedsPassword = true;
}
