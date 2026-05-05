{ lib, pkgs, ... }:
let
  # fcitx5 writes to this file at runtime when switching IMs — deploy as a
  # mutable copy (like codium settings) so nix owns the initial content but
  # fcitx5 can reorder at will. Sentinel re-deploys only when nix source changes.
  profile = pkgs.writeText "fcitx5-profile" ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=keyboard-us

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=mozc
    Layout=

    [Groups/0/Items/2]
    Name=pinyin
    Layout=

    [Groups/0/Items/3]
    Name=m17n:th_kedmanee
    Layout=

    [GroupOrder]
    0=Default
  '';
in
{
  home.packages = with pkgs; [
    fcitx5
    fcitx5-mozc
    fcitx5-m17n
    qt6Packages.fcitx5-chinese-addons
    qt6Packages.fcitx5-configtool
    fcitx5-gtk
  ];

  # Propagate IM env vars to all user processes via the systemd user environment
  # (inherited by niri and every app it spawns on the Wayland session).
  systemd.user.sessionVariables = {
    XMODIFIERS    = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE  = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  # Auto-start fcitx5 when the graphical session comes up.
  systemd.user.services.fcitx5 = {
    Unit = {
      Description = "Fcitx5 input method framework";
      PartOf       = [ "graphical-session.target" ];
      After        = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "simple";
      ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Input method groups: EN-US keyboard, JP MOZC, ZH Pinyin, TH Kedmanee.
  home.activation.fcitx5Profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/.config/fcitx5/profile"
    sentinel="$HOME/.config/fcitx5/.profile-nix-src"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${profile}" ]; then
      cp "${profile}" "$dest"
      chmod u+w "$dest"
      printf '%s' "${profile}" > "$sentinel"
    fi
  '';
}
