{ config, ... }:
let
  wallpaper = ./homepage.png;

  # Everforest dark palette
  bg        = "#2D353B";
  surface   = "#343F44";
  overlay   = "#3D484D";
  text      = "#D3C6AA";
  muted     = "#859289";
  border    = "#475258";
  primary   = "#A7C080";
  secondary = "#D699B6";
  tertiary  = "#83C092";
  green     = "#A7C080";
  red       = "#E67E80";
  yellow    = "#DBBC7F";
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
      "/tank/services/nextcloud"
      "/tank/services/jellyfin"
      "/tank/services/navidrome"
      "/tank/services/postgresql"
      "/tank/services/forgejo"
    ];
  };

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8083;
    allowedHosts = "localhost:8083,homepage.${config.networking.hostName}";
    environmentFile = config.sops.templates."homepage-env".path;

    settings = {
      title = "Landing - ${config.networking.hostName}";
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
      # List preserves order; attrset would sort alphabetically.
      layout = [
        { Infrastructure = { style = "row";    columns = 2; }; }
        { Media          = { style = "column"; }; }
        { Productivity   = { style = "column"; }; }
        { Tools          = { style = "column"; }; }
        { FileBrowsers   = { style = "row";    columns = 4; }; }
      ];
    };

    customCSS = ''
      @import url('https://fonts.googleapis.com/css2?family=DM+Sans:opsz@9..40&display=swap');

      .theme-gray {
        font-family: 'DM Sans', sans-serif;
        zoom: 1.1;

        --color-200: 211 198 170 !important;
        --color-700: 71 82 88 !important;
        --color-800: 52 63 68 !important;
        --color-900: 45 53 59 !important;
        --color-logo-start: 133 146 137 !important;
        --color-logo-stop: 71 82 88 !important;

        --standard-bg: rgba(61, 72, 77, 0.55);

        --info-widgets:        ${primary};
        --resource-bar-bg:     var(--standard-bg);
        --resource-bar-fg:     ${green};
        --widget-border:       ${overlay};
        --service-group:       ${secondary};
        --service-name:        ${text};
        --service-description: ${primary};
        --service-block-bg:    ${surface};
        --service-block-text:  ${secondary};
        --card-color:          ${surface};
        --card-color-hover:    ${overlay};
        --footer-items:        ${secondary};
        --scrollbar-fg:        ${secondary};
        --scrollbar-bg:        var(--standard-bg);

        #information-widgets { border-color: ${overlay}; }
        .information-widget-datetime * { color: ${primary}; }
        .information-widget-openmeteo * { color: ${tertiary}; }
        .information-widget-search svg  { color: ${secondary}; }
        .information-widget-resource    { color: ${muted}; }

        .resource-usage { background-color: var(--standard-bg); }
        .resource-usage > div { background-color: ${green}; }

        .service-group-icon > div { background: ${secondary} !important; }
        .service-group-name       { color: ${secondary} !important; }
        .services-group > button > svg { color: ${secondary}; }

        .service-card       { background-color: ${surface} !important; }
        .service-card:hover { background-color: ${overlay} !important; }
        .service-name.text-sm        { font-size: 0.95rem; color: ${text}; }
        .service-description.text-xs { font-size: 0.75rem; color: ${primary}; }
        .service img { border-radius: 25%; }

        .service-block { background: ${surface}; }
        .service-block .uppercase { color: ${secondary}; }
        .service-block .font-thin  { color: ${text}; }

        #footer svg { color: ${secondary}; }
        * { --scrollbar-thumb: ${secondary}; --scrollbar-track: var(--standard-bg); }

        /* Tailwind color → Everforest */
        .bg-amber-500, .bg-orange-400, .bg-orange-500 { background-color: ${primary}; }
        .bg-blue-500, .bg-sky-500, .bg-cyan-500 { background-color: ${tertiary}; }
        .bg-emerald-500, .bg-green-500, .bg-lime-500 { background-color: ${green}; }
        .bg-fuchsia-500, .bg-pink-500, .bg-violet-500,
        .bg-purple-500, .bg-indigo-500 { background-color: ${secondary}; }
        .bg-red-500, .bg-rose-500 { background-color: ${red}; }
        .bg-yellow-500 { background-color: ${yellow}; }
        .bg-white { background-color: ${text}; }
        .text-white { color: ${text}; }
        .text-red-400, .text-red-500, .text-rose-300, .text-rose-500 { color: ${red}; }
        .text-green-500, .text-emerald-300 { color: ${green}; }
        .service-tags .dark\:bg-theme-900\/50 { background-color: rgb(var(--color-900) / 0.3) !important; }
      }

      /* hostname inline with datetime; search grows to fill row */
      .information-widget-datetime {
        display: flex;
        align-items: baseline;
        gap: 1.25rem;
      }
      .information-widget-datetime::before {
        content: "${config.networking.hostName}";
        font-size: 1.5rem;
        font-weight: 700;
        color: ${primary};
        letter-spacing: 0.06em;
        text-transform: uppercase;
        flex-shrink: 0;
      }
      .information-widget-search { flex: 1 1 300px !important; }

      /* background: centered cover */
      .fixed.min-h-screen {
        background-position: center center !important;
        background-size: cover !important;
      }

      /* center page */
      #page_wrapper { width: 100%; }

      /* scrollbar */
      ::-webkit-scrollbar { width: 5px; }
      ::-webkit-scrollbar-track { background: ${bg}; }
      ::-webkit-scrollbar-thumb { background: ${border}; border-radius: 3px; }
      ::-webkit-scrollbar-thumb:hover { background: ${secondary}; }
    '';

    widgets = [
      # Row 1: hostname (::before) + datetime
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
      # Row 2: search + weather
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
      # Row 3: disk usage (left-aligned via CSS order: 3 + flex: 0 0 auto)
      { resources = { label = "System";      cpu = true; memory = true; disk = "/"; }; }
      { resources = { label = "Anime";       disk = "/tank/media/anime"; }; }
      { resources = { label = "Music";       disk = "/tank/media/music"; }; }
      { resources = { label = "Public NAS";  disk = "/tank/nas/public"; }; }
      { resources = { label = "Backups";     disk = "/tank/backups"; }; }
      { resources = { label = "Nextcloud";   disk = "/tank/services/nextcloud"; }; }
      { resources = { label = "Jellyfin";    disk = "/tank/services/jellyfin"; }; }
      { resources = { label = "Navidrome";   disk = "/tank/services/navidrome"; }; }
      { resources = { label = "PostgreSQL";  disk = "/tank/services/postgresql"; }; }
      { resources = { label = "Forgejo";     disk = "/tank/services/forgejo"; }; }
    ];

    services = [
      # Infrastructure
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
      # Media (column — sits alongside Productivity and Tools)
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
      # Productivity (column)
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
      # Tools (column)
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
