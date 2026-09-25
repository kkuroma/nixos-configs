{ pkgs, lib, osConfig, ... }:
let
  isDesktop = osConfig.host.profile == "desktop";
in
{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.git = {
    enable = true;
    package = lib.mkIf isDesktop pkgs.gitFull; # ships with everything, including secret
    settings = {
      user = {
        name = "kkuroma";
        email = "contact@kuroma.dev";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.autocrlf = "input";
      credential.helper = lib.mkIf isDesktop "${pkgs.gitFull}/bin/git-credential-libsecret";

      # signed git commits
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519.pub";
      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
    };
  };

  home.file.".config/git/allowed_signers".text = ''
    contact@kuroma.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcf33fgUY81ov0I6i+6ZJGGURkRwITQDDr3fgjlMid0 kuroma@zaphkiel
    contact@kuroma.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINofwHa5GuqtIg7RGhFnr+2HrGncuwEK5EHlFEIE8gQU kuroma@raziel
    contact@kuroma.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdECqSc5BelDTphh9qJegx4eqwK32I9tTRn0RsorZ3i kuroma@metatron
  '';
}
