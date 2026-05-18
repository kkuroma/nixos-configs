{ pkgs, lib, config, ... }:
{
  sops.secrets."samba/kuroma" = {};
  sops.secrets."samba/ct" = {};
  sops.secrets."samba/pt" = {};

  services.samba = {
    enable = true;
    openFirewall = false;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "metatron";
        "server role" = "standalone server";
        "map to guest" = "never";
        "interfaces" = "lo tailscale0";
        "bind interfaces only" = "yes";
        "log level" = "1";
      };
      anime = {
        "path" = "/tank/media/anime";
        "read only" = "no";
        "valid users" = "kuroma";
      };
      music = {
        "path" = "/tank/media/music";
        "read only" = "no";
        "valid users" = "kuroma";
      };
      kuroma = {
        "path" = "/tank/nas/kuroma";
        "read only" = "no";
        "valid users" = "kuroma";
      };
      ct = {
        "path" = "/tank/nas/ct";
        "read only" = "no";
        "valid users" = "ct kuroma";
      };
      pt = {
        "path" = "/tank/nas/pt";
        "read only" = "no";
        "valid users" = "pt kuroma";
      };
      public = {
        "path" = "/tank/nas/public";
        "read only" = "no";
        "valid users" = "@family";
      };
      backups = {
        "path" = "/tank/backups";
        "read only" = "no";
        "valid users" = "kuroma";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    interface = "tailscale0";
  };

  systemd.services.samba-passwords = {
    description = "Set Samba user passwords";
    after = [ "samba-smbd.service" "sops-install-secrets.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.samba ];
    script =
      let
        setPass = user: secret: ''
          pass=$(cat ${secret})
          printf '%s\n%s\n' "$pass" "$pass" | smbpasswd -s -a ${user} 2>/dev/null || \
          printf '%s\n%s\n' "$pass" "$pass" | smbpasswd -s ${user}
        '';
      in ''
        ${setPass "kuroma" config.sops.secrets."samba/kuroma".path}
        ${setPass "ct"     config.sops.secrets."samba/ct".path}
        ${setPass "pt"     config.sops.secrets."samba/pt".path}
      '';
  };
}
