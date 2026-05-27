{ config, lib, pkgs, ... }:
let
  imvCopy = pkgs.writeShellScript "imv-copy" ''
    cat "$1" | ${pkgs.wl-clipboard}/bin/wl-copy
    ${pkgs.libnotify}/bin/notify-send -a "System" "Image Copied" "Copied $1 to clipboard" -i preferences-desktop
  '';
in
{
  imports = [
    ./fonts.nix
    ./ghostty.nix
    ./konsole.nix
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

  services.cliphist.enable = true;

  xdg.configFile."fastfetch/config.jsonc".source = ../config/fastfetch/config.jsonc;

  xdg.configFile."noctalia/colorschemes/Material Ocean/Material Ocean.json".source =
    ../config/noctalia/colorschemes/material-ocean/material-ocean.json;

  xdg.configFile."noctalia/colorschemes/Material Ocean Dark/Material Ocean Dark.json".source =
    ../config/noctalia/colorschemes/material-ocean-dark/material-ocean-dark.json;

  xdg.configFile."noctalia/colorschemes/Natsumikan/Natsumikan.json".source =
    ../config/noctalia/colorschemes/Natsumikan/Natsumikan.json;

  xdg.configFile."noctalia/colorschemes/Haruhana/Haruhana.json".source =
    ../config/noctalia/colorschemes/Haruhana/Haruhana.json;

  xdg.configFile."noctalia/colorschemes/Akiba/Akiba.json".source =
    ../config/noctalia/colorschemes/Akiba/Akiba.json;

  xdg.configFile."noctalia/colorschemes/Teto/Teto.json".source =
    ../config/noctalia/colorschemes/Teto/Teto.json;

  xdg.configFile."noctalia/colorschemes/Fuyuyuki/Fuyuyuki.json".source =
    ../config/noctalia/colorschemes/Fuyuyuki/Fuyuyuki.json;

  xdg.configFile."noctalia/colorschemes/Miku/Miku.json".source =
    ../config/noctalia/colorschemes/Miku/Miku.json;

  xdg.configFile."noctalia/user-templates.toml".source =
    ../config/noctalia/user-templates.toml;

  xdg.configFile."noctalia/templates/fcitx5-theme.conf".source =
    ../config/noctalia/templates/fcitx5-theme.conf;

  xdg.configFile."noctalia/templates/nvim-theme.lua".source =
    ../config/noctalia/templates/nvim-theme.lua;

  # mpv thumbnail scripts (from config/mpv/)
  xdg.configFile."mpv/scripts/mpv_thumbnail_script_client_osc.lua".source =
    ../config/mpv/mpv_thumbnail_script_client_osc.lua;
  xdg.configFile."mpv/scripts/mpv_thumbnail_script_server.lua".source =
    ../config/mpv/mpv_thumbnail_script_server.lua;

  xdg.configFile."imv/config".text = ''
    [options]
    overlay = true
    overlay_font = ${config.rice.fonts.ui}:${toString config.rice.fonts.uiSize}
    overlay_text = [$imv_current_index/$imv_file_count] [ESC: Quit] [Ctrl-C: Copy Path] [$imv_width x $imv_height] $imv_scale% $(basename "$imv_current_file")

    [binds]
    <Ctrl+c> = exec ${imvCopy} "$imv_current_file"
    <Escape> = quit
  '';

  # Fallback noctaliarc so zathura doesn't fail before noctalia runs
  home.activation.zathuraNoctaliarcFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.config/zathura/noctaliarc" ]; then
      mkdir -p "$HOME/.config/zathura"
      echo "# placeholder — noctalia will overwrite this" \
        > "$HOME/.config/zathura/noctaliarc"
    fi
  '';
}
