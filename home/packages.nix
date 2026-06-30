{ pkgs, lib, osConfig, ... }:
# Install user-level packages plus gated specific packages
let
  h = osConfig.host.home;
in
{
  home.packages = with pkgs;
    [
      # ── core desktop (always present on a graphical host) ──
      # GUI
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
      mullvad-browser  # secondary/privacy browser (replaced librewolf, unmaintained/insecure in nixpkgs)
      upscayl

      # cli tools
      starship
      brightnessctl
      playerctl
      tesseract
      imagemagick
      zbar
      ffmpeg
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
      aria2

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
      pwvucontrol
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
    ]
    # ── networking bundle ──
    ++ lib.optionals h.networking [
      wireshark
      iperf
    ];
}
