{ pkgs, config, ... }:
{
  services.caddy.virtualHosts = {
    "pdf.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8085";
    "http://pdf.kuroma.dev".extraConfig             = "reverse_proxy localhost:8085";
  };

  systemd.services.stirling-pdf = {
    description = "Stirling PDF";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      SERVER_PORT = "8085";
      HOME = "/var/lib/stirling-pdf";
    };
    serviceConfig = {
      ExecStart = "${pkgs.stirling-pdf}/bin/Stirling-PDF";
      DynamicUser = true;
      RuntimeDirectory = "stirling-pdf";
      WorkingDirectory = "/run/stirling-pdf";
      Restart = "on-failure";
    };
  };
}
