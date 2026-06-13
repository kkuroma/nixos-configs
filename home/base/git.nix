{ ... }:
{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "kkuroma";
        email = "contact@kuroma.dev";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.autocrlf = "input";
    };
  };
}
