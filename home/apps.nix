{ pkgs, inputs, config, lib, machineConfig, ... }:
let
  # Bake the locked nixpkgs rev into init-shell so generated project flakes pin to
  # the same nixpkgs the system was built with, preventing package version skew.
  initShell = pkgs.writeShellScriptBin "init-shell" (
    builtins.replaceStrings ["@NIXPKGS_REV@"] [inputs.nixpkgs.rev]
      (builtins.readFile ./scripts/init-shell.sh)
  );

  compressMkv = pkgs.writeShellScriptBin "compress-mkv"
    (builtins.readFile ./scripts/compress-mkv.sh);

  upscaleMkv = pkgs.writeShellScriptBin "upscale-mkv"
    (builtins.readFile ./scripts/upscale-mkv.sh);

  # fd -> fzf files inside a given directory (home) and launches selected file in vscodium
  codeLauncher = pkgs.writeShellScriptBin "code-launcher" ''
    path=$(${pkgs.fd}/bin/fd -H -E .git -t f -t d . ~/ \
      | ${pkgs.fzf}/bin/fzf \
          --pointer="" \
          --marker="" \
          --prompt="Open in VSCode: " \
          --height=100% \
          --reverse \
          --preview="${pkgs.bat}/bin/bat --color=always --style=numbers {}" \
          --preview-window=right:50%:wrap \
          --color=fg:7,bg:-1,hl:4,fg+:7,bg+:-1,hl+:4,info:2,prompt:4,pointer:3,marker:7,spinner:7,header:4)
    if [ -n "$path" ]; then
      nohup ${pkgs.vscodium}/bin/codium --ozone-platform=wayland "$path" > /dev/null 2>&1 &
      ${pkgs.libnotify}/bin/notify-send -a "System" "Code launcher" "Launched VSCode: $path" -i preferences-desktop
    fi
  '';

  # code launcher, but for dolphin
  fileLauncher = pkgs.writeShellScriptBin "file-launcher" ''
    # -t d restricts fd to directories only
    # --max-depth can be added if ~/ is too slow
    path=$(${pkgs.fd}/bin/fd -H -E .git -t d . ~/ \
      | ${pkgs.fzf}/bin/fzf \
          --pointer="▶" \
          --marker="" \
          --prompt="Open Folder: " \
          --height=100% \
          --reverse \
          --preview="${pkgs.lsd}/bin/lsd --tree --depth 2 --color always {}" \
          --preview-window=right:50%:wrap \
          --color=fg:7,bg:-1,hl:4,fg+:7,bg+:-1,hl+:4,info:2,prompt:4,pointer:3,marker:7,spinner:7,header:4)

    if [ -n "$path" ]; then
      # Use setsid or disown to ensure the process survives the terminal closing
      setsid ${pkgs.kdePackages.dolphin}/bin/dolphin "$path" > /dev/null 2>&1 &
      ${pkgs.libnotify}/bin/notify-send -a "System" "File Browser" "Opening: $path" -i folder-open
    fi
  '';
in
{
  config = {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";
    };

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

    programs.zathura = {
      enable = true;
      options = {
        font = "${config.rice.fonts.ui} ${toString config.rice.fonts.uiSize}";
        recolor = false;
        scroll-step = 80;
        zoom-min = 10;
        zoom-max = 1000;
        guioptions = "sv";
      };
      extraConfig = "include ${config.xdg.configHome}/zathura/noctaliarc";
    };
    
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.packages = with pkgs; [
      # development
      claude-code
      codeLauncher
      fileLauncher
      initShell
      compressMkv
      upscaleMkv
      texliveFull
      (python3.withPackages (ps: with ps; [ tqdm numpy pandas scipy matplotlib requests ipython ]))
      uv
      nodejs

      # nvim formatters (used by conform-nvim)
      nixfmt
      black
      stylua
      prettier

      # GUI apps
      orca-slicer
      feishin
      obs-studio
      vesktop
      (vivaldi.override { proprietaryCodecs = true; enableWidevine = true; })
      networkmanagerapplet
      kdePackages.kdenlive
      kdePackages.gwenview
      kdePackages.konsole
      ### boated ass dolphin + indexers ###
      kdePackages.dolphin
      kdePackages.kfilemetadata
      kdePackages.baloo
      kdePackages.baloo-widgets
      kdePackages.ffmpegthumbs
      ### end of the bloat ###
      krita
      prismlauncher
      imv
      onlyoffice-desktopeditors
      qbittorrent
      librewolf
      puddletag
      logseq
      upscayl

      # cli tools
      brightnessctl
      playerctl
      bat
      tesseract
      imagemagick
      zbar
      curl
      ffmpeg
      jq
      gifski
      grim
      imagemagick
      slurp
      distrobox
      util-linux
      fastfetch
      ouch
      gamescope
      wl-mirror
      hyprpicker # colorpicker needs it
      video2x

      # themes
      wl-screenrec
      wl-clipboard

      # desktop shell
      papirus-icon-theme
      kdePackages.breeze
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      adwaita-qt6
      adw-gtk3

      # etc
      kdePackages.ark
      kdePackages.kde-cli-tools
      gnome-disk-utility
      libnotify
    ];
  }; # end config
}
