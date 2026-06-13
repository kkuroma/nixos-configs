{ ... }:
{
  # Override Steam .desktop entries with StartupNotify=false to trick noctalia to not check
  # if there's already a running instance which prevents subsequent startups
  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam %U";
    icon = "steam";
    comment = "Application for managing and playing games on Steam";
    categories = [ "Network" "FileTransfer" "Game" ];
    startupNotify = false;
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
}
