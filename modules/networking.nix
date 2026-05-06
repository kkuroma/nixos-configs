{ ... }:
{
  networking.networkmanager.enable = true;

  # tailscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--exit-node-allow-lan-access=true"
    ];
  };

  # syncthing
  services.syncthing = {
    enable = true;
    user = "kuroma";
    dataDir = "/home/kuroma";
    settings.folders."Documents" = {
      path = "/home/kuroma/Documents";
    };
    settings.folders."PrismInstances" = {
      path = "/home/kuroma/.local/share/PrismLauncher/instances";
    };
    settings.folders."Wallpapers" = {
      path = "/home/kuroma/Pictures/Wallpaper";
    };
  };
}
