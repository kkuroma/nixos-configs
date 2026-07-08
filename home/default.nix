{ lib, osConfig, ... }:
# Single HM entry point for every host: base/ always, dev/ whenever host.home.dev (servers too),
# graphical layers only on desktop profile. The machine's tickbox is the host = {…} block.
let
  home = osConfig.host.home;
  isDesktop = osConfig.host.profile == "desktop";
in
{
  imports = [ ./base ]
    ++ lib.optionals home.dev [ ./dev ]
    ++ lib.optionals isDesktop [
      ./packages.nix
      ./flatpak.nix
      ./fonts.nix
      ./scripts
      ./programs
      ./desktop
    ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";

  # Login avatar — only graphical hosts have a greeter that shows it.
  home.file = lib.mkIf isDesktop { ".face".source = ../config/.face; };
}
