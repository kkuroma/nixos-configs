{ config, lib, ... }:
{
  services.postgresql = {
    enable = true;
    dataDir = if config.networking.hostName == "metatron" then "/tank/services/postgresql" else "/Vault/postgresql";
  };

  # recordsize=8k matches PostgreSQL's page size — set once manually after dataset creation:
  # zfs set recordsize=8k tank/services/postgresql
  systemd.services.postgresql = lib.mkMerge [
    (lib.mkIf (config.networking.hostName == "metatron") {
      after = [ "zfs-datasets.service" ];
      requires = [ "zfs-datasets.service" ];
    })
    (lib.mkIf (config.networking.hostName != "metatron") {
      after = [ "Vault.mount" ];
      requires = [ "Vault.mount" ];
    })
  ];
}
