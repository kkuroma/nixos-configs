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
  ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";

  services.cliphist.enable = true;

  xdg.configFile."fastfetch/config.jsonc".source = ../config/fastfetch/config.jsonc;

  xdg.configFile."noctalia/colorschemes/Material Ocean/Material Ocean.json".source =
    ../config/noctalia/colorschemes/material-ocean/material-ocean.json;
}
