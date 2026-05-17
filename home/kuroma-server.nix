{ ... }:
{
  imports = [
    ./fonts.nix
    ./git.nix
    ./nushell.nix
    ./nvim.nix
    ./qt.nix
    ./starship.nix
    ./zsh.nix
  ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
}
