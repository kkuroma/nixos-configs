{ config, lib, ... }:
let
  cfg = config.host.services.postgresql or null;
in
{
  services.postgresql = lib.mkIf (cfg != null && cfg.enable) {
    enable = true;
    dataDir = cfg.dataDir;
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
}
