{ lib, osConfig, ... }:
# Single HM entry point for the `kuroma` user on every host. `base/` is always imported.
# `dev/` (headless-safe dev tooling) loads whenever host.home.dev — including on servers,
# with noctalia-free fallbacks. The graphical layers load only when host.profile = "desktop".
# The machine's whole tickbox lives in its configuration.nix `host = {…}` block.
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
