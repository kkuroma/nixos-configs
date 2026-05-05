{ pkgs, ... }:
{
  # Rebuild KDE's service database once per graphical session.
  # Without this, Dolphin's "Open With" dialog is empty because the cache
  # that indexes all installed .desktop files has never been built.
  systemd.user.services.kbuildsycoca6 = {
    Unit = {
      Description = "Rebuild KDE service configuration cache";
      After       = [ "graphical-session-pre.target" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "oneshot";
      ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # PDF / ebooks
      "application/pdf"        = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip"   = [ "org.pwmt.zathura.desktop" ];
      "application/x-cbz"      = [ "org.pwmt.zathura.desktop" ];

      # Images — imv
      "image/jpeg"    = [ "imv.desktop" ];
      "image/png"     = [ "imv.desktop" ];
      "image/gif"     = [ "imv.desktop" ];
      "image/webp"    = [ "imv.desktop" ];
      "image/tiff"    = [ "imv.desktop" ];
      "image/bmp"     = [ "imv.desktop" ];
      "image/x-bmp"   = [ "imv.desktop" ];
      "image/avif"    = [ "imv.desktop" ];
      "image/heif"    = [ "imv.desktop" ];
      "image/svg+xml" = [ "imv.desktop" ];

      # Video — mpv
      "video/mp4"        = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm"       = [ "mpv.desktop" ];
      "video/x-msvideo"  = [ "mpv.desktop" ];
      "video/quicktime"  = [ "mpv.desktop" ];
      "video/x-flv"      = [ "mpv.desktop" ];
      "video/ogg"        = [ "mpv.desktop" ];
      "video/mpeg"       = [ "mpv.desktop" ];
      "video/x-ms-wmv"   = [ "mpv.desktop" ];
      "video/3gpp"       = [ "mpv.desktop" ];

      # Audio — mpv
      "audio/mpeg"       = [ "mpv.desktop" ];
      "audio/flac"       = [ "mpv.desktop" ];
      "audio/ogg"        = [ "mpv.desktop" ];
      "audio/x-wav"      = [ "mpv.desktop" ];
      "audio/mp4"        = [ "mpv.desktop" ];
      "audio/aac"        = [ "mpv.desktop" ];
      "audio/x-opus+ogg" = [ "mpv.desktop" ];

      # Text / code — nvim (Terminal=true in nvim.desktop, TerminalApplication=ghostty in kdeglobals)
      "text/plain"               = [ "nvim.desktop" ];
      "text/x-script.python"     = [ "nvim.desktop" ];
      "text/x-c"                 = [ "nvim.desktop" ];
      "text/x-c++"               = [ "nvim.desktop" ];
      "text/x-shellscript"       = [ "nvim.desktop" ];
      "application/x-shellscript" = [ "nvim.desktop" ];
      "application/json"         = [ "nvim.desktop" ];
      "text/markdown"            = [ "nvim.desktop" ];

      # Web / URLs — Vivaldi
      "text/html"              = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/http"  = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/ftp"   = [ "vivaldi-stable.desktop" ];

      # Office documents — OnlyOffice
      "application/msword"                                                           = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"      = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-excel"                                                     = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"            = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-powerpoint"                                                = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"    = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.text"                                      = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.spreadsheet"                               = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.presentation"                              = [ "onlyoffice-desktopeditors.desktop" ];
    };
  };

  # Dolphin right-click service menu for image transforms.
  # Uses absolute nix store paths so the menu works regardless of PATH.
  xdg.dataFile."kio/servicemenus/reimage.desktop".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=image/jpeg;image/png;image/gif;image/webp;image/tiff;image/bmp;image/x-bmp;image/avif;image/svg+xml;
    Actions=Resize50;Resize75;Resize25;RotateCW;RotateCCW;FlipH;FlipV;ConvertPNG;ConvertJPG;ConvertWEBP;

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
  '';
}
