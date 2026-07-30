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
    };
  };
}
