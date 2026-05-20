{ config, ... }:
let
  wallpaper = ../homepage-wallpaper.png;
in
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

  # Serve the wallpaper from the Nix store via a Caddy handle block
  services.caddy.virtualHosts."homepage.${config.networking.hostName}".extraConfig = ''
    tls internal
    handle /wallpaper.png {
      root * /
      rewrite * ${wallpaper}
      file_server
    }
    reverse_proxy localhost:8083
  '';

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
      color = "gray";
      headerStyle = "underlined";
      iconStyle = "theme";
      cardBlur = "md";
      statusStyle = "dot";
      background = {
        image = "/wallpaper.png";
        blur = "md";
        saturate = 100;
        brightness = 50;
        opacity = 85;
      };
      layout = {
        Media        = { style = "row"; columns = 2; };
        Productivity = { style = "row"; columns = 3; };
        Tools        = { style = "row"; columns = 3; };
        Infrastructure = { style = "row"; columns = 2; };
        FileBrowsers = { style = "row"; columns = 4; };
      };
    };

    customCSS = ''
      @import url('https://fonts.googleapis.com/css2?family=DM+Sans:opsz@9..40&family=Fira+Code&family=Poppins&family=Source+Code+Pro&family=Work+Sans&display=swap');

      .theme-gray {
        font-family: 'DM Sans', sans-serif;
        zoom: 1.15;

        --catppuccin-background: #181825;
        --catppuccin-background-dark: #11111b;
        --catppuccin-foreground: #1e1e2e;
        --catppuccin-text: #cdd6f4;
        --catppuccin-surface: #6272a4;
        --catppuccin-cyan: #89dceb;
        --catppuccin-teal: #94e2d5;
        --catppuccin-green: #a6e3a1;
        --catppuccin-orange: #fab387;
        --catppuccin-pink: #f5c2e7;
        --catppuccin-purple: #cba6f7;
        --catppuccin-lavender: #b4befe;
        --catppuccin-red: #f38ba8;
        --catppuccin-maroon: #eba0ac;
        --catppuccin-yellow: #f9e2af;

        --color-50: 249 250 251 !important;
        --color-100: 243 244 246 !important;
        --color-200: 215 214 244 !important;
        --color-300: 209 213 219 !important;
        --color-400: 156 163 175 !important;
        --color-500: 107 114 128 !important;
        --color-600: 75 85 99 !important;
        --color-700: 55 65 81 !important;
        --color-800: 30 30 46 !important;
        --color-900: 17 17 27 !important;
        --color-logo-start: 156 163 175 !important;
        --color-logo-stop: 55 65 81 !important;

        --standard-bg: #44475a8e;
        --info-widgets: var(--catppuccin-purple);
        --resource-bar-bg: var(--standard-bg);
        --resource-bar-fg: var(--catppuccin-green);
        --widget-border: var(--catppuccin-foreground);
        --service-group: var(--catppuccin-purple);
        --service-name: var(--catppuccin-text);
        --service-description: var(--catppuccin-maroon);
        --service-block-bg: #1e1e2e;
        --service-block-text: var(--catppuccin-pink);
        --card-color: #181825;
        --card-color-hover: #232336;
        --footer-items: var(--catppuccin-pink);
        --scrollbar-fg: var(--catppuccin-purple);
        --scrollbar-bg: var(--standard-bg);

        .service-tags .dark\:bg-theme-900\/50 {
          background-color: rgb(var(--color-900) / 0.3) !important;
        }

        #information-widgets {
          border-color: var(--widget-border);
        }
        #information-widgets * {
          color: var(--info-widgets);
        }

        .resource-usage {
          background-color: var(--resource-bar-bg);
        }
        .resource-usage > div {
          background-color: var(--resource-bar-fg);
        }

        .service-group-icon > div {
          background: var(--service-group) !important;
        }
        .service-group-name {
          color: var(--service-group) !important;
        }
        .services-group > button > svg {
          color: var(--service-group);
        }
        .service-card {
          background-color: var(--card-color) !important;
        }
        .service-card:hover {
          background-color: var(--card-color-hover) !important;
        }
        .service-name.text-sm {
          font-size: 0.95rem;
          color: var(--service-name);
        }
        .service-description.text-xs {
          font-size: 0.75rem;
          color: var(--service-description);
        }
        .service img {
          border-radius: 25%;
        }
        .service-block {
          background: var(--service-block-bg);
        }
        .service-block .uppercase {
          color: var(--service-block-text);
        }
        .service-block .font-thin {
          color: var(--catppuccin-text);
        }

        #footer svg {
          color: var(--footer-items);
        }

        * {
          --scrollbar-thumb: var(--scrollbar-fg);
          --scrollbar-track: var(--scrollbar-bg);
        }

        .bg-amber-500  { background-color: var(--catppuccin-orange); }
        .bg-blue-500   { background-color: var(--catppuccin-cyan); }
        .bg-cyan-500   { background-color: var(--catppuccin-cyan); }
        .bg-emerald-500 { background-color: var(--catppuccin-green); }
        .bg-fuchsia-500 { background-color: var(--catppuccin-pink); }
        .bg-green-500  { background-color: var(--catppuccin-green); }
        .bg-indigo-500 { background-color: var(--catppuccin-purple); }
        .bg-orange-500 { background-color: var(--catppuccin-orange); }
        .bg-pink-500   { background-color: var(--catppuccin-pink); }
        .bg-purple-500 { background-color: var(--catppuccin-purple); }
        .bg-red-500    { background-color: var(--catppuccin-red); }
        .bg-rose-500   { background-color: var(--catppuccin-red); }
        .bg-sky-500    { background-color: var(--catppuccin-cyan); }
        .bg-teal-500   { background-color: #94e2d5; }
        .bg-violet-500 { background-color: var(--catppuccin-purple); }
        .bg-yellow-500 { background-color: var(--catppuccin-yellow); }
        .bg-white      { background-color: var(--catppuccin-text); }
        .text-white    { color: var(--catppuccin-text); }
        .text-red-400  { color: var(--catppuccin-red); }
        .text-red-500  { color: var(--catppuccin-red); }
        .text-green-500 { color: var(--catppuccin-green); }
        .text-emerald-300 { color: var(--catppuccin-green); }
      }

      /* ── widget bar layout ── */
      #widgets-wrap {
        padding: 0.75rem 1.5rem;
      }
      #information-widgets,
      #information-widgets-right {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 0.75rem;
      }

      /* ── hostname title above datetime ── */
      .information-widget-datetime {
        flex: 0 0 100% !important;
      }
      .information-widget-datetime::before {
        display: block;
        content: "metatron";
        font-size: 1.6rem;
        font-weight: 700;
        color: var(--catppuccin-purple);
        letter-spacing: 0.04em;
        text-transform: uppercase;
        margin-bottom: 0.1rem;
      }

      /* ── search + weather row ── */
      .information-widget-search { flex: 1 1 300px !important; }
      .information-widget-openmeteo { flex: 0 0 auto !important; }

      /* ── resource monitors: all on one row ── */
      .information-widget-resource {
        flex: 1 1 0 !important;
        min-width: 120px;
      }

      /* ── background: centered cover ── */
      .fixed.min-h-screen {
        background-position: center center !important;
        background-size: cover !important;
      }

      /* ── center services ── */
      #page_wrapper {
        max-width: 1400px;
        margin: 0 auto;
      }
    '';

    widgets = [
      # ── 1: title row (datetime, hostname injected via CSS ::before) ──
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
      # ── 2–3: search + weather ──
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
      # ── 4–8: system monitors (all one row) ──
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
              href = "https://adguardhome.metatron";
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
