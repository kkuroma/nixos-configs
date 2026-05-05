{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = false;

  users.users.kuroma = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    hashedPassword = "$y$j9T$q1KbTSd8p6jH.MCZirPKO1$MjP3mLcVvv8I5OxOWUXGJpnlQl8.00CuAJuYp3RZ1O.";
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... kuroma@laptop"  # add after generating laptop key
    ];
  };

  users.users.root.hashedPassword = "$y$j9T$8/khyVHG1ds2LT6WAJp4S0$p7cnlmIxez3mE2LJKv4Zfiw3Up534xVcHbMNTSvvVH2";


  security.sudo.wheelNeedsPassword = true;
}
