{ config, lib, ... }:
{
  services.postgresql = {
    enable = true;
    dataDir = if config.networking.hostName == "metatron" then "/tank/services/postgresql" else "/Vault/postgresql";
    identMap = ''
      superuser_map kuroma   postgres
      superuser_map kuroma   kuroma
      superuser_map postgres postgres
    '';
    authentication = lib.mkAfter ''
      local all kuroma   peer map=superuser_map
      local all postgres peer map=superuser_map
    '';
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
