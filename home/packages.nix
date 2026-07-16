{ pkgs, lib, osConfig, ... }:
# THE single entry point for install-only user packages: desktop core + gated bundles
# + the headless dev toolchain (h.dev works on any profile, servers included).
let
  h = osConfig.host.home;
  desk = osConfig.host.profile == "desktop";
in
{
  home.packages = with pkgs;
    # ── core desktop (always present on a graphical host) ──
    lib.optionals desk [
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
      bibata-cursors
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
    # ── dev bundle: headless toolchain (any profile) ──
    ++ lib.optionals h.dev [
      (python3.withPackages (ps: with ps; [ tqdm numpy pandas scipy matplotlib requests ipython ]))
      uv
      nodejs
      claude-code
      distrobox
      # nvim formatters (conform-nvim)
      nixfmt
      black
      stylua
      prettier
    ]
    # ── media bundle (mpv itself is home/programs/mpv.nix) ──
    ++ lib.optionals h.media [
      feishin
      obs-studio
      puddletag
      kdePackages.kdenlive
      pwvucontrol
    ]
    # ── office bundle ──
    ++ lib.optionals h.office [
      onlyoffice-desktopeditors
      texliveFull # LaTeX for vscodium latex-workshop + nvim vimtex
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
    ]
    # ── 3d-printing bundle (BambuStudio flatpak is home/3d-printing.nix) ──
    ++ lib.optionals h."3d-printing" [
      openscad
    ];
}
