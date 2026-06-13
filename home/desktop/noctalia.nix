{ inputs, lib, osConfig, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf osConfig.host.home.noctalia {
  programs.noctalia = {
    enable = true;

    # The binary stays a SYSTEM package (parts/modules/niri.nix) so
    # /run/current-system/sw/bin/noctalia keeps existing for raziel's charge-limit udev
    # rule + swayidle. package = null makes this module emit config.toml only, without
    # also installing noctalia into the HM profile (no double install, no path churn).
    package = null;
    systemd.enable = false;

    # ── Declarative BASE layer → ~/.config/noctalia/config.toml ──────────────────
    # v5 merges config PER-KEY: built-in defaults → config.toml (this) → state
    # (~/.local/state/noctalia/settings.toml, GUI/IPC, wins). So everything here is a
    # host-agnostic default that the GUI can still override. Intentionally NOT declared
    # (left fully mutable in state): [theme] (palette/mode), [wallpaper], and the
    # monitor-coupled layouts [desktop_widgets] + [lockscreen_widgets] (they embed
    # connector names like HDMI-A-1 and would be wrong on raziel's eDP-1). [bar.*] and
    # [widget.*] ARE declared here — they carry no monitor names, so they're portable;
    # the trade-off is that bar/widget tweaks now need a rebuild instead of a live GUI drag.
    settings = {
      backdrop = {
        enabled = true;
        blur_intensity = 0.5; # blurred wallpaper in niri overview (place-within-backdrop)
        tint_intensity = 0.0;
      };

      # Bar layout + appearance. Float vs int types mirror what noctalia's parser writes
      # (e.g. border_width = 2.0 float, radius = 20 int) — keep them as-is.
      bar = {
        order = [ "Top" "workspaces" ];

        Top = {
          border_width = 2.0;
          capsule = true;
          capsule_radius = 45;
          start = [ "launcher" "group:g3" "active_window" ];
          center = [ "wallpaper" "group:g5" "control-center" ];
          end = [ "tray" "group:g2" "group:g1" "battery" "session" ];
          margin_edge = 0;
          margin_ends = 8;
          padding = 10;
          panel_overlap = 0;
          radius = 20;
          radius_top_left = 0;
          radius_top_right = 0;
          scale = 1.1;
          thickness = 40;

          capsule_group = [
            { id = "g1"; fill = "surface_variant"; members = [ "cpu" "temp" "ram" ]; opacity = 1.0; padding = 6.0; }
            { id = "g2"; fill = "surface_variant"; members = [ "network" "bluetooth" "volume" ]; opacity = 1.0; padding = 6.0; }
            { id = "g3"; fill = "surface_variant"; members = [ "clock" "notifications" ]; opacity = 1.0; padding = 6.0; }
            { id = "g5"; fill = "surface_variant"; foreground = "primary"; border = ""; members = [ "media" "audio_visualizer" ]; opacity = 1.0; padding = 6.0; radius = 45.0; }
          ];
        };

        workspaces = {
          enabled = true;
          auto_hide = true;
          border_width = 1.5;
          position = "left";
          start = [ ];
          center = [ "workspaces" ];
          end = [ ];
          margin_edge = 0;
          margin_ends = 380;
          radius = 20;
          radius_bottom_left = 0;
          radius_top_left = 0;
          reserve_space = false;
          thickness = 39;
        };
      };

      # Per-widget tuning (keys mirror [widget.<name>]; "control-center" needs quoting).
      widget = {
        audio_visualizer.width = 100.0;
        battery.capsule = true;
        clock.format = "{:%Y/%m/%d-%H:%M:%S}";
        "control-center".capsule = true;
        cpu = { capsule = true; show_label = false; };
        media = { art_size = 20.0; max_length = 160; min_length = 160; title_scroll = "on_hover"; };
        network.show_label = false;
        ram = { capsule = true; show_label = false; };
        recorder.type = "noctalia/screen_recorder:recorder";
        recorder_2.type = "noctalia/screen_recorder:recorder";
        screenshot.capsule = true;
        session.capsule = true;
        sysmon.stat = "net_tx";
        temp = { capsule = true; show_label = false; };
        tray = { capsule = true; drawer = true; };
        volume = { capsule = true; show_label = false; };
        wallpaper.capsule = true;
        workspaces = { anchor = true; capsule = true; display = "name"; labels_only_when_occupied = true; scale = 1.3; };
      };

      control_center.sidebar_section = "none";

      dock = {
        active_monitor_only = true;
        auto_hide = true;
        enabled = true;
        launcher_icon = "snowflake";
        launcher_position = "start";
      };

      location.address = "Tokyo, Japan";

      plugins = {
        enabled = [ "noctalia/screen_recorder" ];
        source = [
          { kind = "git"; name = "official"; location = "https://github.com/noctalia-dev/official-plugins"; }
          { kind = "git"; name = "community"; location = "https://github.com/noctalia-dev/community-plugins"; }
        ];
      };

      shell = {
        avatar_path = "~/.face";
        corner_radius_scale = 1.2;
        font_family = "Maple Mono NF CN";
        niri_overview_type_to_launch_enabled = true;
        polkit_agent = true;
        screen_time_enabled = true;
        settings_show_advanced = true;
        ui_scale = 1.2;

        panel = {
          clipboard_placement = "attached";
          open_near_click_control_center = true;
          session_placement = "centered";
        };

        session.actions = [
          { action = "lock"; enabled = true; shortcut = "1"; variant = "default"; }
          { action = "logout"; enabled = true; shortcut = "2"; variant = "default"; }
          { action = "lock_and_suspend"; enabled = true; shortcut = "3"; variant = "default"; }
          { action = "reboot"; enabled = true; shortcut = "4"; variant = "default"; }
          { action = "command"; enabled = true; command = "systemctl hibernate"; glyph = "zzz"; label = "Hibernate"; variant = "default"; }
          { action = "shutdown"; enabled = true; shortcut = "5"; variant = "destructive"; }
        ];
      };

      # Template engine. fcitx5 has no community template, so it is declared inline as a
      # v5 user template (replaces the legacy config/noctalia/user-templates.toml + the
      # GUI "User templates" toggle). nvim is handled by the community 'neovim' template.
      theme.templates = {
        enable_builtin_templates = true;
        builtin_ids = [ "btop" "gtk3" "gtk4" "ghostty" "kcolorscheme" "niri" "qt" "starship" ];
        enable_community_templates = true;
        community_ids = [ "neovim" "vscode" "discord" "yazi" "zathura" ];

        user.fcitx5 = {
          enabled = true;
          input_path = "~/.config/noctalia/templates/fcitx5-theme.conf";
          output_path = "~/.local/share/fcitx5/themes/noctalia/theme.conf";
          post_hook = "kill -9 $(pgrep fcitx5); fcitx5 -d &";
        };
      };
    };
  };

  # Static inputs noctalia reads from ~/.config/noctalia (not generated at runtime):
  #   palettes/ — custom color schemes, whole dir; v5 picks <Name>.json via
  #               `noctalia msg color-scheme-set custom <name>`. Each file is dark-only
  #               (a `dark` block of mPrimary… roles + terminal); v5 derives light at runtime.
  #   templates/fcitx5-theme.conf — input for the inline [theme.templates.user.fcitx5] above.
  xdg.configFile."noctalia/palettes".source = ../../config/noctalia/palettes;
  xdg.configFile."noctalia/templates/fcitx5-theme.conf".source =
    ../../config/noctalia/templates/fcitx5-theme.conf;
  };
}
