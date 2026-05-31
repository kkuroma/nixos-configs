{ config, lib, ... }:
let
  cfg = config.host.services.neo4j or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."neo4j/password" = {};

  services.neo4j = {
    enable = true;
    https.enable = false;
    http.enable = true;
    directories.home = cfg.dataDir;
  };
}
