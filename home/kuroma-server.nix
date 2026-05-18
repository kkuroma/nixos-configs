{ ... }:
{
  imports = [
    ./git.nix
    ./nushell.nix
    ./zsh.nix
  ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
}
