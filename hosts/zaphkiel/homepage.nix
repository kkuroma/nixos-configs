{ config, ... }:
let
  wallpaper = ./homepage.png;

  # Catppuccin Mocha palette
  bg        = "#1E1E2E";
  surface   = "#313244";
  overlay   = "#45475A";
  text      = "#CDD6F4";
  muted     = "#A6ADC8";
  border    = "#585B70";
  primary   = "#CBA6F7";
  secondary = "#89B4FA";
  tertiary  = "#94E2D5";
  green     = "#A6E3A1";
  red       = "#F38BA8";
  yellow    = "#F9E2AF";
in
{
  sops.secrets."adguard/password" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/latitude" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/longitude" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/location" = { mode = "0444"; };
  sops.secrets."homepage/${config.networking.hostName}/timezone" = { mode = "0444"; };

  sops.templates."homepage-env" = {
    mode = "0444";
    content = ''
      HOMEPAGE_VAR_ADGUARD_PASSWORD=${config.sops.placeholder."adguard/password"}
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

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8083;
    allowedHosts = "localhost:8083,homepage.${config.networking.hostName}";
    environmentFiles = [ config.sops.templates."homepage-env".path ];

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
      layout = [
        { Infrastructure = { style = "row"; columns = 2; }; }
        { AI = { style = "row"; columns = 5; }; }
        { Tools  = { style = "column"; }; }
      ];
    };

    customCSS = ''
      @import url('https://fonts.googleapis.com/css2?family=DM+Sans:opsz@9..40&display=swap');

      .theme-gray {
        font-family: 'DM Sans', sans-serif;
        zoom: 1.1;

        --color-200: 205 214 244 !important;
        --color-700: 88 91 112 !important;
        --color-800: 49 50 68 !important;
        --color-900: 30 30 46 !important;
        --color-logo-start: 166 173 200 !important;
        --color-logo-stop: 88 91 112 !important;

        --standard-bg: rgba(88, 91, 112, 0.55);

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

      .fixed.min-h-screen {
        background-position: center center !important;
        background-size: cover !important;
      }

      #page_wrapper { width: 100%; }

      ::-webkit-scrollbar { width: 5px; }
      ::-webkit-scrollbar-track { background: ${bg}; }
      ::-webkit-scrollbar-thumb { background: ${border}; border-radius: 3px; }
      ::-webkit-scrollbar-thumb:hover { background: ${secondary}; }
    '';

    widgets = [
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
      { resources = { label = "System"; cpu = true; memory = true; disk = "/"; }; }
      { resources = { label = "Nix"; disk = "/nix"; }; }
      { resources = { label = "Storage"; disk = "/mnt/Vault-Storage"; }; }
      { resources = { label = "Academics"; disk = "/mnt/Vault-Academics"; }; }
      { resources = { label = "Entertainment"; disk = "/mnt/Vault-Entertainment"; }; }
    ];

    services = [
      {
        "Infrastructure" = [
          {
            "AdGuard Home" = {
              href = "https://adguard.zaphkiel";
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
            Beszel = {
              href = "https://beszel.zaphkiel";
              description = "Server monitoring";
              icon = "beszel.png";
              ping = "https://beszel.zaphkiel";
            };
          }
          {
            Syncthing = {
              href = "https://syncthing.zaphkiel";
              description = "File sync";
              icon = "syncthing.png";
              ping = "https://syncthing.zaphkiel";
            };
          }
        ];
      }
      {
        "AI" = [
          {
            "LLaMA Router" = {
              href = "http://zaphkiel:11434";
              description = "Local LLM API";
              icon = "ollama.png";
              ping = "http://localhost:11434";
            };
          }
          {
            LibreChat = {
              href = "https://librechat.zaphkiel";
              description = "Chat UI + GraphIV deep research";
              icon = "librechat.png";
              ping = "https://librechat.zaphkiel";
            };
          }
          {
            GraphIV = {
              href = "https://graphiv.zaphkiel";
              description = "arXiv deep-research MCP";
              icon = "arxiv.png";
              ping = "https://graphiv.zaphkiel";
            };
          }
          {
            n8n = {
              href = "https://n8n.zaphkiel";
              description = "Workflow automation";
              icon = "n8n.png";
              ping = "https://n8n.zaphkiel";
            };
          }
          {
            Neo4j = {
              href = "https://neo4j.zaphkiel";
              description = "Graph database";
              icon = "neo4j.png";
              ping = "https://neo4j.zaphkiel";
            };
          }
        ];
      }
      {
        "Tools" = [
          {
            Cockpit = {
              href = "https://cockpit.zaphkiel";
              description = "System management";
              icon = "cockpit.png";
              ping = "https://cockpit.zaphkiel";
            };
          }
        ];
      }
    ];
  };
}
