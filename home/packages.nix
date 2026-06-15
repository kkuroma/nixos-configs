{ pkgs, lib, osConfig, ... }:
# Install-only packages, gated by host.home.* bundles (the file itself only loads on
# desktop hosts — see home/default.nix). Core desktop tools are ungated; bundle-specific
# apps ride their tick. Configured apps install via their home/programs/<name>.nix.
let
  h = osConfig.host.home;
in
{
  home.packages = with pkgs;
    [
      # ── core desktop (always present on a graphical host) ──
      # GUI
      wireshark
      orca-slicer
      vesktop
      (vivaldi.override { proprietaryCodecs = true; enableWidevine = true; })
      networkmanagerapplet
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
      imv
      qbittorrent
      librewolf
      upscayl

      # cli tools
      lsd
      starship
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
      slurp
      util-linux
      fastfetch
      ouch
      wl-mirror
      hyprpicker # colorpicker needs it
      video2x
      wl-screenrec
      wl-clipboard

      # desktop shell / theming
      papirus-icon-theme
      kdePackages.breeze
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      adwaita-qt6
      adw-gtk3

      # etc
      kdePackages.ark
      unrar
      p7zip
      kdePackages.kde-cli-tools
      gnome-disk-utility
      libnotify
    ]
    # ── media bundle (mpv itself is home/programs/mpv.nix) ──
    ++ lib.optionals h.media [
      feishin
      obs-studio
      puddletag
      kdePackages.kdenlive
    ]
    # ── dev bundle (desktop-only bits; headless toolchain is home/dev/packages.nix) ──
    ++ lib.optionals h.dev [
      texliveFull # LaTeX for vscodium latex-workshop + nvim vimtex (desktop)
    ]
    # ── office bundle ──
    ++ lib.optionals h.office [
      onlyoffice-desktopeditors
    ]
    # ── gaming bundle ──
    ++ lib.optionals h.gaming [
      prismlauncher
      osu-lazer-bin
      gamescope
    ];
}
