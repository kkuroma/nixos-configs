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
    # nixpkgs' neo4j module drops the JDK module-opens that upstream Neo4j ships.
    # Without --add-opens=java.base/java.nio=ALL-UNNAMED the JDK-21 server cannot
    # build native vector indexes (HNSW merge needs DirectByteBuffer via Unsafe);
    # population silently stalls at ~99.8%. These restore the upstream set.
    extraServerConfig = ''
      server.jvm.additional=--add-opens=java.base/java.nio=ALL-UNNAMED
      server.jvm.additional=--add-opens=java.base/java.io=ALL-UNNAMED
      server.jvm.additional=--add-opens=java.base/sun.nio.ch=ALL-UNNAMED
      server.jvm.additional=-Dio.netty.tryReflectionSetAccessible=true
    '';
  };
}
