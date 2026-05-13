{ ... }:
{
  # swayidle installed and configured to lock screen BEFORE sleep/hibernate
  services.swayidle = {
    enable = true;
    extraArgs = [ "-w" ];
    events = {
      before-sleep = "/run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock";
    };
  };

}
