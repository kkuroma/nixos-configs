{ config, lib, ... }:
# Mirrors host.services: declare here, tick per-host, each home/ module gates on its flag.
let
  desk = config.host.profile == "desktop";
in
{
  options.host.home = {
    noctalia = lib.mkOption {
      type = lib.types.bool;
      default = desk;
      description = "noctalia shell present — route app theming through its runtime palettes (vs static defaults).";
    };
    media = lib.mkOption {
      type = lib.types.bool;
      default = desk;
      description = "media bundle: mpv + feishin/obs/puddletag/gwenview.";
    };
    office = lib.mkOption {
      type = lib.types.bool;
      default = desk;
      description = "office bundle: onlyoffice.";
    };
    dev = lib.mkOption {
      type = lib.types.bool;
      default = desk;
      description = "dev bundle: vscodium, nvim, language toolchains + formatters.";
    };
    gaming = lib.mkOption {
      type = lib.types.bool;
      default = desk;
      description = "gaming bundle: prismlauncher, osu-lazer, gamescope.";
    };
    networking = lib.mkOption {
      type = lib.types.bool;
      default = desk;
      description = "kali linux networking tools like nmap, traceroute, wireshark.";
    };
  };
}
