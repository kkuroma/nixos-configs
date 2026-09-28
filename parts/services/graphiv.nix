{ config, lib, pkgs, ... }:

# GraphIV (git.kuroma.dev/kkuroma/graphiv): a grounded literature review endpoint over arXiv.
# Its own module emits two units from one package, the nine tools on cfg.port and the dashboard
# beside it. Every option it exposes is written out below, defaults included, since this file is
# the whole record of how the service is deployed here.
let
  cfg = config.host.services.graphiv or null;
  llama = config.host.services.llama or { port = 11434; };
  frontendPort = (cfg.port or 6767) + 202;

  # the full text is on a different mount than the rest, so name the resolved paths and not the
  # symlinks under dataDir, or the unit orders on Vault.mount alone and a read misses in silence
  corpus = "/mnt/Vault-Storage/research/arxiv";

  # the cluster this host supplies: one postmaster of its own, not the system postgresql on 5432
  postgres = pkgs.postgresql_17.withPackages (p: [ p.pgvector ]);
  cluster = "${cfg.dataDir or "/Vault/graphiv"}/data/pg";
  socket = "/run/graphiv";
  port = 5433;
in
lib.mkIf (cfg != null && cfg.enable) {
  services.graphiv = {
    enable = true;
    package = pkgs.graphiv;

    user = "graphiv";
    group = "graphiv";

    # /Vault stands in for /var/lib here, and data, cache and runs default under it
    stateDir = cfg.dataDir;
    dataDir = "${cfg.dataDir}/data";
    cacheDir = "${cfg.dataDir}/cache";
    runsDir = "${cfg.dataDir}/runs";

    listenAddress = "127.0.0.1";
    # every name caddy forwards, since the transport rejects a Host it is not bound to
    allowedHosts =
      [ "graphiv.${config.networking.hostName}" ]
      ++ lib.optional (cfg.publicHost != null) cfg.publicHost;

    # a paper neither store has is pulled from arXiv into the corpus itself
    fetch = true;
    recipes = "${pkgs.graphiv}/share/graphiv/retrieval_recipes";

    database.dsn = "host=${socket} port=${toString port} dbname=arxivkg";

    corpus = {
      graph = "${cfg.dataDir}/data/citation_graph_export.npy";
      html = "${corpus}/html";
      pdf = "${corpus}/pdfs";
    };

    endpoints = {
      embed.url = "http://127.0.0.1:11435";
      embed.name = "nomic-embed-text-v2-moe";
      llm.url = "http://127.0.0.1:${toString llama.port}/v1";
      llm.name = "Gemma-4-26B-Batched";
    };

    api = {
      enable = true;
      port = cfg.port;
      readOnly = false;
    };

    frontend = {
      enable = true;
      port = frontendPort;
    };

    settings = { };
  };

  # kuroma still runs the preprocess stages against the same tree, so both write it
  users.users.kuroma.extraGroups = [ "graphiv" ];

  # The project's own postmaster, socket only, owned by graphiv. -k overrides whatever
  # unix_socket_directories the cluster's postgresql.conf still says.
  systemd.services.graphiv-pg = {
    description = "GraphIV postgres";
    wantedBy = [ "multi-user.target" ];
    after = [ "Vault.mount" ];
    requires = [ "Vault.mount" ];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${postgres}/bin/postgres -D ${cluster} -k ${socket} -p ${toString port}";
      User = "graphiv";
      Group = "graphiv";
      RuntimeDirectory = "graphiv";
      RuntimeDirectoryMode = "0755";
      Restart = "on-failure";
      RestartSec = 10;
      TimeoutStartSec = "5min";
      TimeoutStopSec = "10min";
      KillSignal = "SIGINT";
      KillMode = "mixed";
      # logind clears POSIX shm for a uid >= 1000 on logout, which a backend attaching to a
      # dynamic segment then dies on; a system user is exempt and this says so out loud
      RemoveIPC = false;
      OOMScoreAdjust = -900;
    };
  };

  systemd.services.graphiv-api = {
    after = [ "graphiv-pg.service" "llama-router.service" "llama-embed.service" ];
    requires = [ "graphiv-pg.service" ];
  };

  # The tunnel reaches the dashboard, which is a process carrying no tools and no store handle, so
  # a forgotten matcher cannot expose one. Full access stays on the tailnet vhost. The host sets
  # internal = false and publicAuto = false, since both vhosts are written here.
  services.caddy.virtualHosts = {
    "graphiv.${config.networking.hostName}".extraConfig = ''
      tls internal
      reverse_proxy localhost:${toString cfg.port}
    '';
  } // lib.optionalAttrs (cfg.publicHost != null) {
    "http://${cfg.publicHost}".extraConfig = ''
      reverse_proxy localhost:${toString frontendPort}
    '';
  };
}
