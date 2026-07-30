{ lib, osConfig, ... }:
# Single HM entry point for every host: base/ + packages.nix always
let
  home = osConfig.host.home;
  isDesktop = osConfig.host.profile == "desktop";
in
{
  imports = [ ./base ./packages.nix ]
    ++ lib.optionals home.dev [ ./dev ]
    ++ lib.optionals isDesktop [
      ./3d-printing.nix
      ./fonts.nix
      ./scripts
      ./programs
      ./desktop
    ];

  home.username = "kuroma";
  home.homeDirectory = "/home/kuroma";
  home.stateVersion = "25.11";
  home.file = lib.mkIf isDesktop { ".face".source = ../config/.face; };
}
