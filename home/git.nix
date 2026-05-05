{ ... }:
{
  programs.git = {
    enable = true;
    userName  = "kuroma";
    userEmail = "laoganma960@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase         = false;
      core.autocrlf       = "input";
    };
  };
}
