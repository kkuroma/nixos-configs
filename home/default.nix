{ lib, osConfig, ... }:
# Single HM entry point for every host: base/ + packages.nix always (packages self-gate on
# profile/bundles), dev/ whenever host.home.dev (servers too), graphical layers only on
# desktop profile. The machine's tickbox is the host = {…} block.
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

  # Login avatar — only graphical hosts have a greeter that shows it.
  home.file = lib.mkIf isDesktop { ".face".source = ../config/.face; };
}
