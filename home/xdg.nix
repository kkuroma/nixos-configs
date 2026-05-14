{ pkgs, config, lib, machineConfig, ... }:
{
  config = {
    # Override Steam .desktop entries with StartupNotify=false to trick noctaliat to not check
    # if there's already a running instance which prevents subsequent startups
    xdg.desktopEntries.steam = {
      name = "Steam";
      exec = "steam %U";
      icon = "steam";
      comment = "Application for managing and playing games on Steam";
      categories = [ "Network" "FileTransfer" "Game" ];
      startupNotify = false;
    };

    # Minimal applications.menu required by kbuildsycoca6 to build its application service db
    xdg.configFile."menus/applications.menu".text = ''
      <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
        "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
      <Menu>
        <Name>Applications</Name>
        <DefaultAppDirs/>
        <DefaultMergeDirs/>
      </Menu>
    '';

    # Rebuild KDE's service database once per graphical session so dolphon has a "open with" dialog
    systemd.user.services.kbuildsycoca6 = {
      Unit = {
        Description = "Rebuild KDE service configuration cache";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # PDF / ebooks
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
        "application/x-cbz" = [ "org.pwmt.zathura.desktop" ];

        # Images — imv-dir
        "image/jpeg" = [ "imv-dir.desktop" ];
        "image/png" = [ "imv-dir.desktop" ];
        "image/gif" = [ "imv-dir.desktop" ];
        "image/webp" = [ "imv-dir.desktop" ];
        "image/tiff" = [ "imv-dir.desktop" ];
        "image/bmp" = [ "imv-dir.desktop" ];
        "image/x-bmp" = [ "imv-dir.desktop" ];
        "image/avif" = [ "imv-dir.desktop" ];
        "image/heif" = [ "imv-dir.desktop" ];
        "image/svg+xml" = [ "imv-dir.desktop" ];

        # Video — mpv
        "video/mp4" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/ogg" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "video/3gpp" = [ "mpv.desktop" ];

        # Audio — mpv
        "audio/mpeg" = [ "mpv.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "audio/ogg" = [ "mpv.desktop" ];
        "audio/x-wav" = [ "mpv.desktop" ];
        "audio/mp4" = [ "mpv.desktop" ];
        "audio/aac" = [ "mpv.desktop" ];
        "audio/x-opus+ogg" = [ "mpv.desktop" ];

        # Text / code — nvim (Terminal=true in nvim.desktop, TerminalApplication=ghostty in kdeglobals)
        "text/plain" = [ "nvim.desktop" ];
        "text/x-script.python" = [ "nvim.desktop" ];
        "text/x-c" = [ "nvim.desktop" ];
        "text/x-c++" = [ "nvim.desktop" ];
        "text/x-shellscript" = [ "nvim.desktop" ];
        "application/x-shellscript" = [ "nvim.desktop" ];
        "application/json" = [ "nvim.desktop" ];
        "text/markdown" = [ "nvim.desktop" ];

        # Web / URLs — Vivaldi
        "text/html" = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/ftp" = [ "vivaldi-stable.desktop" ];

        # Office documents — OnlyOffice
        "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-powerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
      };
    };

    # Vivaldi custom UI CSS (Settings → Appearance → Custom UI Modifications)
    xdg.configFile."vivaldi-theme/theme.css".text =
      let
        ui   = config.rice.fonts.ui;
        mono = config.rice.fonts.mono;
      in ''
        /* vivaldi font override bc funny hehe */
        * {
          font-family: '${ui}', system-ui, sans-serif !important;
        }

        /* keep icons from breaking */
        .vds-icon,
        .button-icon,
        [class^="icon-"] {
          font-family: 'Vivaldi Icons', vivaldi !important;
        }
      '';

    # video compression service menu — CPU (libx264) and optionally GPU (h264_nvenc) at 3 quality levels
    xdg.dataFile."kio/servicemenus/compress-video.desktop".text = ''
      [Desktop Entry]
      Type=Service
      ServiceTypes=KonqPopupMenu/Plugin
      MimeType=video/mp4;video/x-matroska;video/webm;video/x-msvideo;video/quicktime;video/x-flv;video/ogg;video/mpeg;video/x-ms-wmv;video/3gpp;
      Actions=CpuBest;CpuBal;CpuSmall;${lib.optionalString machineConfig.nvenc "GpuBest;GpuBal;GpuSmall;"}

      [Desktop Action CpuBest]
      Name=Compress — CPU Good Quality
      Icon=video-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v libx264 -preset slow -crf 26 -c:a copy "''${f%.*}_cpu_best.mp4"; done' -- %F

      [Desktop Action CpuBal]
      Name=Compress — CPU Balanced
      Icon=video-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v libx264 -preset medium -crf 32 -c:a copy "''${f%.*}_cpu_bal.mp4"; done' -- %F

      [Desktop Action CpuSmall]
      Name=Compress — CPU Smallest
      Icon=video-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v libx264 -preset fast -crf 38 -c:a copy "''${f%.*}_cpu_small.mp4"; done' -- %F
      ${lib.optionalString machineConfig.nvenc ''

      [Desktop Action GpuBest]
      Name=Compress — GPU (NVENC) Good Quality
      Icon=video-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v h264_nvenc -preset p6 -rc:v vbr -cq 26 -c:a copy "''${f%.*}_gpu_best.mp4"; done' -- %F

      [Desktop Action GpuBal]
      Name=Compress — GPU (NVENC) Balanced
      Icon=video-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v h264_nvenc -preset p4 -rc:v vbr -cq 32 -c:a copy "''${f%.*}_gpu_bal.mp4"; done' -- %F

      [Desktop Action GpuSmall]
      Name=Compress — GPU (NVENC) Smallest
      Icon=video-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v h264_nvenc -preset p2 -rc:v vbr -cq 38 -c:a copy "''${f%.*}_gpu_small.mp4"; done' -- %F
      ''}
    '';

    # OCR service menu — runs tesseract on images and outputs a .txt file
    xdg.dataFile."kio/servicemenus/ocr.desktop".text = ''
      [Desktop Entry]
      Type=Service
      ServiceTypes=KonqPopupMenu/Plugin
      MimeType=image/jpeg;image/png;image/gif;image/webp;image/tiff;image/bmp;image/x-bmp;image/avif;
      Actions=OCRText;

      [Desktop Action OCRText]
      Name=OCR to Text
      Icon=document-new
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.tesseract}/bin/tesseract "$f" "''${f%.*}"; done' -- %F
    '';

    # r-click service menu in dolphin from reimage ported to nix
    xdg.dataFile."kio/servicemenus/reimage.desktop".text = ''
      [Desktop Entry]
      Type=Service
      ServiceTypes=KonqPopupMenu/Plugin
      MimeType=image/jpeg;image/png;image/gif;image/webp;image/tiff;image/bmp;image/x-bmp;image/avif;image/svg+xml;
      Actions=Resize50;Resize75;Resize25;RotateCW;RotateCCW;FlipH;FlipV;ConvertPNG;ConvertJPG;ConvertWEBP;SquareCrop;SquarePad;

      [Desktop Action Resize50]
      Name=Resize to 50%
      Icon=transform-scale
      Exec=${pkgs.imagemagick}/bin/mogrify -resize 50% %F

      [Desktop Action Resize75]
      Name=Resize to 75%
      Icon=transform-scale
      Exec=${pkgs.imagemagick}/bin/mogrify -resize 75% %F

      [Desktop Action Resize25]
      Name=Resize to 25%
      Icon=transform-scale
      Exec=${pkgs.imagemagick}/bin/mogrify -resize 25% %F

      [Desktop Action RotateCW]
      Name=Rotate Clockwise 90°
      Icon=object-rotate-right
      Exec=${pkgs.imagemagick}/bin/mogrify -rotate 90 %F

      [Desktop Action RotateCCW]
      Name=Rotate Counter-Clockwise 90°
      Icon=object-rotate-left
      Exec=${pkgs.imagemagick}/bin/mogrify -rotate -90 %F

      [Desktop Action FlipH]
      Name=Flip Horizontal
      Icon=object-flip-horizontal
      Exec=${pkgs.imagemagick}/bin/mogrify -flop %F

      [Desktop Action FlipV]
      Name=Flip Vertical
      Icon=object-flip-vertical
      Exec=${pkgs.imagemagick}/bin/mogrify -flip %F

      [Desktop Action ConvertPNG]
      Name=Convert to PNG
      Icon=image-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.imagemagick}/bin/convert "$f" "''${f%.*}.png"; done' -- %F

      [Desktop Action ConvertJPG]
      Name=Convert to JPEG
      Icon=image-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.imagemagick}/bin/convert "$f" "''${f%.*}.jpg"; done' -- %F

      [Desktop Action ConvertWEBP]
      Name=Convert to WebP
      Icon=image-x-generic
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.imagemagick}/bin/convert "$f" "''${f%.*}.webp"; done' -- %F

      [Desktop Action SquareCrop]
      Name=Crop to Square (center)
      Icon=image-crop
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do s=$(${pkgs.imagemagick}/bin/identify -format "%[fx:min(w,h)]" "$f"); ${pkgs.imagemagick}/bin/mogrify -gravity Center -crop "''${s}x''${s}+0+0" +repage "$f"; done' -- %F

      [Desktop Action SquarePad]
      Name=Pad to Square (white)
      Icon=image-resize
      Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do s=$(${pkgs.imagemagick}/bin/identify -format "%[fx:max(w,h)]" "$f"); ${pkgs.imagemagick}/bin/mogrify -gravity Center -background white -extent "''${s}x''${s}" "$f"; done' -- %F
    '';
  };
}
