{ pkgs, ... }:
{
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
      StateDirectory = "stirling-pdf";
      Restart = "on-failure";
    };
  };
}
