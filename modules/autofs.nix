{ pkgs, ... }:
let
  nasMap = pkgs.writeText "auto.nas" ''
    anime        -fstype=cifs,credentials=/etc/autofs/nas-credentials,uid=1000,gid=1000 ://100.104.4.37/anime
    songs        -fstype=cifs,credentials=/etc/autofs/nas-credentials,uid=1000,gid=1000 ://100.104.4.37/songs
    backup-home  -fstype=cifs,credentials=/etc/autofs/nas-credentials,uid=1000,gid=1000 ://100.104.4.37/home
    backup-games -fstype=cifs,credentials=/etc/autofs/nas-credentials,uid=1000,gid=1000 ://100.104.4.37/games
  '';
in
{
  environment.systemPackages = [ pkgs.cifs-utils ];

  services.autofs = {
    enable = true;
    autoMaster = ''
      /mnt/NAS ${nasMap} --timeout=0 --ghost --browse
    '';
  };

  systemd.services.autofs = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
  };
}
