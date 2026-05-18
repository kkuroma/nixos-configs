{ pkgs, config, metatronIP, ... }:
let
  creds = config.sops.templates."nas-creds".path;
  nasMap = pkgs.writeText "auto.nas" ''
    anime  -fstype=cifs,credentials=${creds},uid=1000,gid=1000,iocharset=utf8 ://${metatronIP}/anime
    music  -fstype=cifs,credentials=${creds},uid=1000,gid=1000,iocharset=utf8 ://${metatronIP}/music
    kuroma -fstype=cifs,credentials=${creds},uid=1000,gid=1000,iocharset=utf8 ://${metatronIP}/kuroma
  '';
in
{
  sops.secrets."samba/kuroma" = {};
  sops.templates."nas-creds" = {
    content = ''
      username=kuroma
      password=${config.sops.placeholder."samba/kuroma"}
    '';
    mode = "0400";
  };

  environment.systemPackages = [ pkgs.cifs-utils ];

  services.autofs = {
    enable = true;
    autoMaster = ''
      /mnt/NAS ${nasMap} --timeout=0 --ghost --browse
    '';
  };

  systemd.services.autofs = {
    after = [ "tailscaled.service" "sops-install-secrets.service" ];
    wants = [ "tailscaled.service" ];
  };
}

