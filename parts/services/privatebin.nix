{ config, lib, ... }:
let
  cfg = config.host.services.privatebin or null;
in
lib.mkIf (cfg != null && cfg.enable) {
  services.privatebin = {
    enable = true;
    enableNginx = true;
    settings = {
      main = {
        fileupload = true;
        size_limit = 104857600; 
      };
    };
    poolConfig = {
      "php_admin_value[upload_max_filesize]" = "100M";
      "php_admin_value[post_max_size]" = "100M";
      "php_admin_value[memory_limit]" = "256M";
    };
  };

  services.nginx.virtualHosts."localhost".listen = [
    { addr = "127.0.0.1"; port = cfg.port; ssl = false; }
  ];
}
