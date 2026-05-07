{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "kuroma";
        email = "contact@kuroma.dev";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.autocrlf = "input";
    };
  };
}
