{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = false;

  users.users.kuroma = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd"];
    hashedPassword = "$y$j9T$q1KbTSd8p6jH.MCZirPKO1$MjP3mLcVvv8I5OxOWUXGJpnlQl8.00CuAJuYp3RZ1O.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcf33fgUY81ov0I6i+6ZJGGURkRwITQDDr3fgjlMid0 kuroma@zaphkiel"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINofwHa5GuqtIg7RGhFnr+2HrGncuwEK5EHlFEIE8gQU kuroma@raziel"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdECqSc5BelDTphh9qJegx4eqwK32I9tTRn0RsorZ3i kuroma@metatron"
    ];
  };

  users.users.root.hashedPassword = "$y$j9T$8/khyVHG1ds2LT6WAJp4S0$p7cnlmIxez3mE2LJKv4Zfiw3Up534xVcHbMNTSvvVH2";


  security.sudo.wheelNeedsPassword = true;
}
