{ pkgs, machineConfig, lib, osConfig, ... }:
{
  config = lib.mkIf osConfig.host.home.media {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [ mpris ];
      config = {
        hwdec = machineConfig.hwdec; # GPU decoding & rendering
        vo = "gpu-next";
        gpu-api = "vulkan";
        scale = "ewa_lanczossharp"; # playback quality
        dscale = "mitchell";
        cscale = "ewa_lanczossharp";
        keep-open = "yes"; # behaviour
        save-position-on-quit = "yes";
        osd-font-size = 32;
        osc = "no";
      };
      bindings = {
        # Seek
        RIGHT = "seek 5";
        LEFT = "seek -5";
        UP = "seek 60";
        DOWN = "seek -60";
        # Speed
        "[" = "add speed -0.1";
        "]" = "add speed 0.1";
        "{" = "add speed -0.5";
        "}" = "add speed 0.5";
        BS  = "set speed 1.0";
        # Playlist
        PGUP = "playlist-prev";
        PGDWN = "playlist-next";
        # Subtitles
        j = "cycle sub";
        J = "cycle sub down";
        # Audio
        a = "cycle audio";
        A = "cycle audio down";
      };
    };

    # Thumbnail scripts (osc = "no" above; these replace the OSC — see CLAUDE.md MPV note)
    xdg.configFile."mpv/scripts/mpv_thumbnail_script_client_osc.lua".source =
      ../../config/mpv/mpv_thumbnail_script_client_osc.lua;
    xdg.configFile."mpv/scripts/mpv_thumbnail_script_server.lua".source =
      ../../config/mpv/mpv_thumbnail_script_server.lua;
  };
}
