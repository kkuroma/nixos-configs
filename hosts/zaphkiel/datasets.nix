{ pkgs, lib, ... }:

let
  datasets = {
    "vault/media/anime" = {
      mountpoint = "/mnt/Vault-Storage/media/anime";
      owner = "kuroma";
      group = "users";
      mode = "755";
      snapshot = true;
    };
    "vault/media/music" = {
      mountpoint = "/mnt/Vault-Storage/media/music";
      owner = "kuroma";
      group = "users";
      mode = "755";
      snapshot = true;
    };
    "vault/research" = {
      mountpoint = "/mnt/Vault-Storage/research";
      owner = "kuroma";
      group = "users";
      mode = "700";
      snapshot = true;
    };
    "vault/other" = {
      mountpoint = "/mnt/Vault-Storage/other";
      owner = "kuroma";
      group = "users";
      mode = "700";
      snapshot = true;
    };
  };

  mkDataset = name: cfg: ''
    zfs create -p -o mountpoint=${cfg.mountpoint} ${name} 2>/dev/null || true
    zfs set com.sun:auto-snapshot=${if cfg.snapshot or false then "true" else "false"} ${name}
    chown ${cfg.owner}:${cfg.group} ${cfg.mountpoint} 2>/dev/null || true
    chmod ${cfg.mode} ${cfg.mountpoint}
  '';
in
{
  systemd.services.zfs-datasets = {
    description = "Create and configure ZFS datasets (vault)";
    after = [ "zfs-import-vault.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.zfs ];
    script = lib.concatStrings (lib.mapAttrsToList mkDataset datasets);
  };

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 4;
    hourly = 24;
    daily = 7;
    weekly = 4;
    monthly = 3;
  };

  services.zfs.autoScrub = {
    enable = true;
    pools = [ "vault" ];
    interval = "weekly";
  };
}
