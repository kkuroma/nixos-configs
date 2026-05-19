{ ... }:
{
  services.postgresql = {
    enable = true;
    dataDir = "/tank/services/postgresql";
  };

  # recordsize=8k matches PostgreSQL's page size — set once manually after dataset creation:
  # zfs set recordsize=8k tank/services/postgresql
  systemd.services.postgresql = {
    after = [ "zfs-datasets.service" ];
    requires = [ "zfs-datasets.service" ];
  };
}
