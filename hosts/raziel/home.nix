{ ... }:
{
  # raziel-specific: lock screen before sleep via swayidle
  services.swayidle = {
    enable = true;
    extraArgs = [ "-w" ];
    events.before-sleep = "/run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock";
  };
}
