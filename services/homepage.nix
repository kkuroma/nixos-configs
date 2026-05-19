{ config, ... }:
{
  sops.secrets."homepage/jellyfin-api-key" = { mode = "0444"; };
  sops.secrets."adguard/password" = { mode = "0444"; };
  sops.secrets."homepage/navidrome-token" = { mode = "0444"; };
  sops.secrets."homepage/navidrome-salt" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/latitude" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/longitude" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/location" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/timezone" = { mode = "0444"; };

  sops.templates."homepage-env" = {
    mode = "0444";
    content = ''
      HOMEPAGE_VAR_JELLYFIN_API_KEY=${config.sops.placeholder."homepage/jellyfin-api-key"}
      HOMEPAGE_VAR_ADGUARD_PASSWORD=${config.sops.placeholder."adguard/password"}
      HOMEPAGE_VAR_NAVIDROME_TOKEN=${config.sops.placeholder."homepage/navidrome-token"}
      HOMEPAGE_VAR_NAVIDROME_SALT=${config.sops.placeholder."homepage/navidrome-salt"}
      HOMEPAGE_VAR_LATITUDE=${config.sops.placeholder."homepage/${config.networking.hostName}/latitude"}
      HOMEPAGE_VAR_LONGITUDE=${config.sops.placeholder."homepage/${config.networking.hostName}/longitude"}
      HOMEPAGE_VAR_LOCATION=${config.sops.placeholder."homepage/${config.networking.hostName}/location"}
      HOMEPAGE_VAR_TIMEZONE=${config.sops.placeholder."homepage/${config.networking.hostName}/timezone"}
    '';
  };

  services.caddy.virtualHosts."homepage.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:8083";

  systemd.services.homepage-dashboard = {
    after = [ "zfs-datasets.service" "sops-install-secrets.service" ];
    requires = [ "zfs-datasets.service" ];
    serviceConfig.BindReadOnlyPaths = [
      "/tank/media/anime"
      "/tank/media/music"
      "/tank/nas/public"
      "/tank/backups"
    ];
  };

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8083;
    allowedHosts = "localhost:8083,homepage.${config.networking.hostName}";
    environmentFile = config.sops.templates."homepage-env".path;

    settings = {
      title = "metatron";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      layout = {
        Media = { style = "row"; columns = 2; };
        Productivity = { style = "row"; columns = 3; };
        Tools = { style = "row"; columns = 3; };
        Infrastructure = { style = "row"; columns = 2; };
        FileBrowsers = { style = "row"; columns = 4; };
      };
    };

    widgets = [
      {
        resources = {
          label = "System";
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        resources = {
          label = "Anime";
          disk = "/tank/media/anime";
        };
      }
      {
        resources = {
          label = "Music";
          disk = "/tank/media/music";
        };
      }
      {
        resources = {
          label = "Public NAS";
          disk = "/tank/nas/public";
        };
      }
      {
        resources = {
          label = "Backups";
          disk = "/tank/backups";
        };
      }
      {
        search = {
          provider = "custom";
          url = "https://searx.kuroma.dev/search?q=";
          target = "_blank";
          suggestionUrl = "https://searx.kuroma.dev/autocomplete?q=";
          showSearchSuggestions = true;
        };
      }
      {
        openmeteo = {
          label = "{{HOMEPAGE_VAR_LOCATION}}";
          latitude = "{{HOMEPAGE_VAR_LATITUDE}}";
          longitude = "{{HOMEPAGE_VAR_LONGITUDE}}";
          units = "imperial";
          timezone = "{{HOMEPAGE_VAR_TIMEZONE}}";
          cache = 5;
        };
      }
      {
        datetime = {
          text_size = "xl";
          locale = "ja-JP";
          format = {
            timeStyle = "short";
            dateStyle = "short";
            hour12 = false;
          };
        };
      }
    ];

    services = [
      {
        "Media" = [
          {
            Jellyfin = {
              href = "https://jellyfin.metatron";
              description = "Media server";
              icon = "jellyfin.png";
              widget = {
                type = "jellyfin";
                url = "http://localhost:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                enableBlocks = true;
              };
            };
          }
          {
            Navidrome = {
              href = "https://navidrome.metatron";
              description = "Music streaming";
              icon = "navidrome.png";
              widget = {
                type = "navidrome";
                url = "http://localhost:4533";
                user = "kuroma";
                token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
              };
            };
          }
        ];
      }
      {
        "Productivity" = [
          {
            Nextcloud = {
              href = "https://cloud.kuroma.dev";
              description = "Cloud storage";
              icon = "nextcloud.png";
              ping = "https://cloud.kuroma.dev";
            };
          }
          {
            Vaultwarden = {
              href = "https://vault.kuroma.dev";
              description = "Passwords";
              icon = "bitwarden.png";
              ping = "https://vault.kuroma.dev";
            };
          }
          {
            Forgejo = {
              href = "https://git.kuroma.dev";
              description = "Git";
              icon = "forgejo.png";
              ping = "https://git.kuroma.dev";
            };
          }
        ];
      }
      {
        "Tools" = [
          {
            SearXNG = {
              href = "https://searx.kuroma.dev";
              description = "Search";
              icon = "searxng.png";
              ping = "https://searx.kuroma.dev";
            };
          }
          {
            "Stirling PDF" = {
              href = "https://pdf.kuroma.dev";
              description = "PDF tools";
              icon = "stirling-pdf.png";
              ping = "https://pdf.kuroma.dev";
            };
          }
          {
            PrivateBin = {
              href = "https://pastebin.kuroma.dev";
              description = "Pastebin";
              icon = "privatebin.png";
              ping = "https://pastebin.kuroma.dev";
            };
          }
        ];
      }
      {
        "Infrastructure" = [
          {
            "AdGuard Home" = {
              href = "https://adguard.metatron";
              description = "DNS + ad blocking";
              icon = "adguard-home.png";
              widget = {
                type = "adguard";
                url = "http://localhost:3000";
                username = "adguard-admin";
                password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
              };
            };
          }
          {
            Matrix = {
              href = "https://matrix.metatron";
              description = "Chat";
              icon = "matrix-light.png";
              ping = "https://matrix.metatron";
            };
          }
        ];
      }
      {
        "FileBrowsers" = [
          {
            "ct-dump" = {
              href = "https://ct-dump.metatron";
              description = "CT's files";
              icon = "filebrowser.png";
              ping = "https://ct-dump.metatron";
            };
          }
        ];
      }
    ];
  };
}
