{ config, ... }:
let
  wallpaper = ../homepage-wallpaper.png;

  # Natsumikan dark palette
  bg      = "#0D1017";
  surface = "#171D26";
  primary = "#F5803E";
  # secondary = "#C792EA";
  tertiary = "#39BAE6";
  text    = "#D1D1C7";
  muted   = "#8E959E";
  border  = "#242C3A";
  green   = "#AAD94C";
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
      color = "slate";
      headerStyle = "clean";
      cardBlur = "md";
      background = {
        image = "/wallpaper.png";
        blur = "sm";
        saturate = 100;
        brightness = 60;
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
      /* ── Natsumikan palette ── */
      :root {
        --n-bg:      ${bg};
        --n-surface: ${surface};
        --n-primary: ${primary};
        --n-tertiary:${tertiary};
        --n-text:    ${text};
        --n-muted:   ${muted};
        --n-border:  ${border};
        --n-green:   ${green};
      }

      /* ── page base ── */
      body {
        background-color: var(--n-bg);
        color: var(--n-text);
      }

      /* ── glassmorphism cards (.service confirmed) ── */
      .service {
        background: rgba(23, 29, 38, 0.72) !important;
        border: 1px solid ${border} !important;
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
      }

      /* ── theme color overrides with Natsumikan palette ── */
      .primary-text,
      .text-theme-800,
      .text-theme-900,
      .dark .dark\:text-theme-200 { color: ${text} !important; }
      .secondary-text,
      .text-theme-700,
      .dark .dark\:text-theme-300 { color: ${muted} !important; }

      /* ── links ── */
      a { color: var(--n-text); transition: color 0.15s ease; }
      a:hover { color: ${primary} !important; }

      /* ── search input ── */
      input[type="text"],
      input[type="search"] {
        background: rgba(23, 29, 38, 0.9) !important;
        border: 1px solid ${border} !important;
        color: ${text} !important;
        border-radius: 0.5rem;
      }
      .placeholder-theme-900::placeholder { color: ${muted} !important; }
      input:focus {
        border-color: ${primary} !important;
        outline: none;
        box-shadow: 0 0 0 2px rgba(245, 128, 62, 0.25);
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

      /* ── datetime: full-width title row, hostname above it via ::before ── */
      .information-widget-datetime {
        flex: 0 0 100% !important;
      }
      .information-widget-datetime::before {
        display: block;
        content: "metatron";
        font-size: 1.6rem;
        font-weight: 700;
        color: ${primary};
        letter-spacing: 0.04em;
        text-transform: uppercase;
        margin-bottom: 0.1rem;
      }

      /* ── search expands, weather compact ── */
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

      /* ── scrollbar ── */
      ::-webkit-scrollbar       { width: 5px; }
      ::-webkit-scrollbar-track { background: ${bg}; }
      ::-webkit-scrollbar-thumb { background: ${border}; border-radius: 3px; }
      ::-webkit-scrollbar-thumb:hover { background: ${primary}; }
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
