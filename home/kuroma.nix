{ ... }:
{
  imports = [
    ./fonts.nix
    ./ghostty.nix
    ./apps.nix
    ./niri.nix
    ./codium.nix
    ./zsh.nix
    ./nushell.nix
    ./qt.nix
    ./fcitx5.nix
    ./xdg.nix
    ./git.nix
  ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";

  services.cliphist.enable = true;

  xdg.configFile."fastfetch/config.jsonc".source = ../config/fastfetch/config.jsonc;

  xdg.configFile."noctalia/colorschemes/Material Ocean/Material Ocean.json".source =
    ../config/noctalia/colorschemes/material-ocean/material-ocean.json;

  xdg.configFile."noctalia/colorschemes/Material Ocean Dark/Material Ocean Dark.json".source =
    ../config/noctalia/colorschemes/material-ocean-dark/material-ocean-dark.json;
}
