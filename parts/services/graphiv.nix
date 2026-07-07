{ config, lib, pkgs, ... }:

# GraphIV MCP server (git.kuroma.dev/kkuroma/GraphIV) — deep-research tools on
# loopback streamable-http. Runs inside the repo's `nix develop` env as the repo
# owner: project venv, CUDA LD_LIBRARY_PATH, and the project-local Postgres
# (peer auth, socket at <dataDir>/.pg) all come from the dev shell.
# dataDir = the repo checkout; the dev shellHook exports PG* + ARXIVKG_PG_DSN.
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

  # Public (cloudflared) vhost — READ-ONLY. Destructive run actions, pdf compiles,
  # and the MCP transport (deep_research = hours of GPU) answer 403 here; the tailnet
  # vhost graphiv.<host> keeps full access (caddy :80/:443 are tailscale0-only, so
  # reaching that vhost proves VPN-or-local origin). The host entry must set
  # publicAuto = false — this block replaces the glue's plain public vhost.
  # X-GraphIV-Public tells the dashboard to hide the gated UI (cosmetic only).
  services.caddy.virtualHosts = lib.optionalAttrs (cfg.publicHost != null) {
    "http://${cfg.publicHost}".extraConfig = ''
      @closed path /api/run/*/delete /api/run/*/purge-cache /api/run/*/compile-pdf /mcp /mcp/*
      respond @closed 403
      request_header X-GraphIV-Public 1
      reverse_proxy localhost:${toString cfg.port}
    '';
  };
}
