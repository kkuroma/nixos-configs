{ config, lib, pkgs, ... }:

# GraphIV MCP server (git.kuroma.dev/kkuroma/GraphIV): deep-research tools over
# loopback streamable-http, run inside the repo's `nix develop` env as the repo
# owner. dataDir = the checkout; venv/CUDA/project Postgres come from the shellHook.
let
  cfg = config.host.services.graphiv or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  systemd.services.graphiv-mcp = {
    description = "GraphIV MCP server (deep research over arXiv)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "llama-router.service" ];
    path = with pkgs; [ nix git bash coreutils ];
    environment.GRAPHIV_MCP_PORT = toString cfg.port;
    # Public base for run assets (figures/graph.html) in MCP-returned markdown + the
    # run dashboard. Prefers publicHost (resolvable for everyone, incl. shared links);
    # falls back to the tailnet vhost auto-emitted by the services glue.
    environment.GRAPHIV_PUBLIC_URL =
      if cfg.publicHost != null
      then "https://${cfg.publicHost}"
      else "https://graphiv.${config.networking.hostName}";
    script = ''
      cd ${cfg.dataDir}
      exec nix develop . --command bash -c '
        pg-console -c "SELECT 1" >/dev/null 2>&1 || pg-start
        exec python phases/phase-6/serve_mcp.py --http
      '
    '';
    serviceConfig = {
      # Repo owner: peer-auth to the project PG requires the same unix user.
      User = "kuroma";
      Group = "users";
      Restart = "on-failure";
      RestartSec = 10;
      TimeoutStartSec = "15min"; # first start may realize the dev shell
    };
  };

  # Public (cloudflared) vhost is read-only: destructive actions and the MCP
  # transport 403 here, full access stays on the tailnet vhost. Host must set
  # publicAuto = false (this replaces the glue's plain public vhost);
  # X-GraphIV-Public just tells the dashboard to hide the gated UI.
  services.caddy.virtualHosts = lib.optionalAttrs (cfg.publicHost != null) {
    "http://${cfg.publicHost}".extraConfig = ''
      @closed path /api/run/*/delete /api/run/*/purge-cache /api/run/*/compile-pdf /mcp /mcp/*
      respond @closed 403
      request_header X-GraphIV-Public 1
      reverse_proxy localhost:${toString cfg.port}
    '';
  };
}
