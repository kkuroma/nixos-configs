{ ... }:
{
  imports = [
    ./git.nix
    ./nushell.nix
    ./nvim.nix
    ./zsh.nix
  ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
}
