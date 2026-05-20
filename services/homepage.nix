{ config, ... }:
let
  wallpaper = ../homepage-wallpaper.png;

  # Natsumikan dark palette
  bg        = "#0D1017";
  surface   = "#171D26";
  overlay   = "#1E2433";
  text      = "#D1D1C7";
  muted     = "#8E959E";
  border    = "#242C3A";
  primary   = "#F5803E";   # orange
  secondary = "#C792EA";   # purple
  tertiary  = "#39BAE6";   # cyan
  green     = "#AAD94C";
  red       = "#FF5370";
  yellow    = "#FFB454";
  blue      = "#82AAFF";
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
      hideVersion = true;
      background = {
        image = "/wallpaper.png";
        blur = "md";
        saturate = 100;
        brightness = 50;
        opacity = 85;
      };
      layout = {
        Stats          = { style = "row"; columns = 3; };
        Infrastructure = { style = "row"; columns = 2; };
        Productivity   = { style = "column"; };
        Tools          = { style = "column"; };
        FileBrowsers   = { style = "row"; columns = 4; };
      };
    };

    customCSS = ''
      @import url('https://fonts.googleapis.com/css2?family=DM+Sans:opsz@9..40&display=swap');

      /* ── Natsumikan palette mapped onto catppuccin's .theme-gray structure ── */
      .theme-gray {
        font-family: 'DM Sans', sans-serif;
        zoom: 1.1;

        --n-bg:        ${bg};
        --n-surface:   ${surface};
        --n-overlay:   ${overlay};
        --n-text:      ${text};
        --n-muted:     ${muted};
        --n-border:    ${border};
        --n-primary:   ${primary};
        --n-secondary: ${secondary};
        --n-tertiary:  ${tertiary};
        --n-green:     ${green};
        --n-red:       ${red};
        --n-yellow:    ${yellow};
        --n-blue:      ${blue};

        /* homepage theme-color CSS variables (RGB triplets, no #) */
        --color-200: 209 209 199 !important;   /* text */
        --color-700: 36 44 58 !important;      /* border */
        --color-800: 23 29 38 !important;      /* surface */
        --color-900: 13 16 23 !important;      /* bg */
        --color-logo-start: 142 149 158 !important;
        --color-logo-stop:  36 44 58 !important;

        --standard-bg: rgba(36, 44, 58, 0.55);

        /* widget / resource bars */
        --info-widgets:      var(--n-primary);
        --resource-bar-bg:   var(--standard-bg);
        --resource-bar-fg:   var(--n-green);
        --widget-border:     var(--n-overlay);

        /* service cards */
        --service-group:       var(--n-secondary);
        --service-name:        var(--n-text);
        --service-description: var(--n-primary);
        --service-block-bg:    var(--n-surface);
        --service-block-text:  var(--n-secondary);
        --card-color:          ${surface};
        --card-color-hover:    ${overlay};

        /* footer / scrollbar */
        --footer-items: var(--n-secondary);
        --scrollbar-fg: var(--n-secondary);
        --scrollbar-bg: var(--standard-bg);

        /* ── information widgets ── */
        #information-widgets {
          border-color: var(--widget-border);
        }
        #information-widgets * {
          color: var(--n-primary);
        }

        .resource-usage { background-color: var(--resource-bar-bg); }
        .resource-usage > div { background-color: var(--resource-bar-fg); }

        /* ── service groups ── */
        .service-group-icon > div { background: var(--service-group) !important; }
        .service-group-name       { color: var(--service-group) !important; }
        .services-group > button > svg { color: var(--service-group); }

        .service-card       { background-color: var(--card-color) !important; }
        .service-card:hover { background-color: var(--card-color-hover) !important; }

        .service-name.text-sm        { font-size: 0.95rem; color: var(--service-name); }
        .service-description.text-xs { font-size: 0.75rem; color: var(--service-description); }

        .service img { border-radius: 25%; }

        .service-block          { background: var(--service-block-bg); }
        .service-block .uppercase { color: var(--service-block-text); }
        .service-block .font-thin  { color: var(--n-text); }

        /* ── footer ── */
        #footer svg { color: var(--footer-items); }

        /* ── scrollbar ── */
        * {
          --scrollbar-thumb: var(--scrollbar-fg);
          --scrollbar-track: var(--scrollbar-bg);
        }

        /* ── Tailwind color overrides → Natsumikan ── */
        .bg-amber-500, .bg-orange-400, .bg-orange-500 { background-color: ${primary}; }
        .bg-blue-500, .bg-sky-500, .bg-cyan-500       { background-color: ${tertiary}; }
        .bg-emerald-500, .bg-green-500, .bg-lime-500  { background-color: ${green}; }
        .bg-fuchsia-500, .bg-pink-500, .bg-violet-500,
        .bg-purple-500, .bg-indigo-500                { background-color: ${secondary}; }
        .bg-red-500, .bg-rose-500                     { background-color: ${red}; }
        .bg-yellow-500                                { background-color: ${yellow}; }
        .bg-teal-500                                  { background-color: ${tertiary}; }
        .bg-white                                     { background-color: ${text}; }

        .text-white                 { color: ${text}; }
        .text-red-400, .text-red-500, .text-rose-300,
        .text-rose-500, .text-rose-900 { color: ${red}; }
        .text-green-500, .text-emerald-300 { color: ${green}; }
        .text-amber-800             { color: ${primary}; }
        .text-blue-500\/80          { color: ${tertiary}; }
        .text-emerald-500\/80       { color: ${green}; }
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

      /* Row 1: hostname above datetime, spans full width */
      .information-widget-datetime {
        flex: 0 0 100% !important;
      }
      .information-widget-datetime::before {
        display: block;
        content: "${config.networking.hostName}";
        font-size: 1.6rem;
        font-weight: 700;
        color: ${primary};
        letter-spacing: 0.06em;
        text-transform: uppercase;
        margin-bottom: 0.15rem;
      }

      /* Row 2: search expands, weather anchors right */
      .information-widget-search    { flex: 1 1 300px !important; }
      .information-widget-openmeteo { flex: 0 0 auto !important; }

      /* Row 3: resource monitors share one row equally */
      .information-widget-resource {
        flex: 1 1 0 !important;
        min-width: 110px;
      }

      /* Background: centered cover */
      .fixed.min-h-screen {
        background-position: center center !important;
        background-size: cover !important;
      }

      /* Center page content */
      #page_wrapper {
        max-width: 1400px;
        margin: 0 auto;
      }

      /* Scrollbar */
      ::-webkit-scrollbar       { width: 5px; }
      ::-webkit-scrollbar-track { background: ${bg}; }
      ::-webkit-scrollbar-thumb { background: ${border}; border-radius: 3px; }
      ::-webkit-scrollbar-thumb:hover { background: ${secondary}; }
    '';

    widgets = [
      # Row 1 — hostname (via CSS ::before) + datetime
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
      # Row 2 — search + weather
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
      # Row 3 — system + disk usage (SMART health not natively available without glances)
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
      # Stats row — services with live widget data
      {
        "Stats" = [
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
      # Infrastructure row
      {
        "Infrastructure" = [
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
      # Columns — Productivity
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
      # Columns — Tools
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
      # FileBrowsers row — bottom
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
