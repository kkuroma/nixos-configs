{ config, ... }:
{
  imports = [
    ./fonts.nix
    ./ghostty.nix
    ./apps.nix
    ./nvim.nix
    ./niri.nix
    ./codium.nix
    ./zsh.nix
    ./nushell.nix
    ./starship.nix
    ./qt.nix
    ./fcitx5.nix
    ./xdg.nix
    ./git.nix
  ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";

  home.file.".face".source = ../config/.face;

  home.file."Shells" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/System/nixos-configs/shells";
  };

  services.cliphist.enable = true;

  xdg.configFile."fastfetch/config.jsonc".source = ../config/fastfetch/config.jsonc;

  xdg.configFile."noctalia/colorschemes/Material Ocean/Material Ocean.json".source =
    ../config/noctalia/colorschemes/material-ocean/material-ocean.json;

  xdg.configFile."noctalia/colorschemes/Material Ocean Dark/Material Ocean Dark.json".source =
    ../config/noctalia/colorschemes/material-ocean-dark/material-ocean-dark.json;

  xdg.configFile."noctalia/user-templates.toml".source =
    ../config/noctalia/user-templates.toml;

  xdg.configFile."noctalia/templates/fcitx5-theme.conf".source =
    ../config/noctalia/templates/fcitx5-theme.conf;

  xdg.configFile."noctalia/templates/nvim-theme.lua".source =
    ../config/noctalia/templates/nvim-theme.lua;
}
