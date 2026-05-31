{ config, lib, pkgs, ... }:
let
  cfg = config.host.services.forgejo or null;
  customDir = "${config.services.forgejo.stateDir}/custom";
  fontFile = ../../config/fonts/GoogleSansFlex-VariableFont.ttf;
  iconPng = pkgs.runCommand "forgejo-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    convert ${./icon.webp} $out
  '';

  # Standalone Forgejo theme — placed at {customDir}/public/assets/css/theme-natsumikan.css
  # and declared in ui.THEMES so Forgejo registers it.
  themeCSS = pkgs.writeText "theme-natsumikan.css" ''
    @font-face {
      font-family: 'Google Sans Flex';
      src: url('/assets/fonts/GoogleSansFlex-VariableFont.ttf') format('truetype');
      font-weight: 100 900;
      font-style: normal;
      font-display: swap;
    }

    :root {
      /* Natsumikan dark surface scale */
      --ns-900: #0A0C12;
      --ns-850: #0D1017;
      --ns-800: #101520;
      --ns-750: #141A22;
      --ns-700: #171D26;
      --ns-650: #1D2530;
      --ns-600: #222C38;
      --ns-550: #242C3A;
      --ns-500: #2C3545;
      --ns-450: #384250;
      --ns-400: #454F5E;
      --ns-350: #535D6D;
      --ns-300: #626C7C;
      --ns-250: #717C8C;
      --ns-200: #8E959E;
      --ns-150: #B0B8C1;
      --ns-100: #D1D1C7;

      /* Map steel-* to ns-* so any steel references in base CSS still resolve */
      --steel-900: var(--ns-900);
      --steel-850: var(--ns-850);
      --steel-800: var(--ns-800);
      --steel-750: var(--ns-750);
      --steel-700: var(--ns-700);
      --steel-650: var(--ns-650);
      --steel-600: var(--ns-600);
      --steel-550: var(--ns-550);
      --steel-500: var(--ns-500);
      --steel-450: var(--ns-450);
      --steel-400: var(--ns-400);
      --steel-350: var(--ns-350);
      --steel-300: var(--ns-300);
      --steel-250: var(--ns-250);
      --steel-200: var(--ns-200);
      --steel-150: var(--ns-150);
      --steel-100: var(--ns-100);

      --is-dark-theme: true;

      /* Primary — Natsumikan orange */
      --color-primary:           #F5803E;
      --color-primary-contrast:  #0D1017;
      --color-primary-dark-1:    #F9B070;
      --color-primary-dark-2:    #F9B070;
      --color-primary-dark-3:    #FAC090;
      --color-primary-dark-4:    #FAC090;
      --color-primary-dark-5:    #FBD0B0;
      --color-primary-dark-6:    #FBD0B0;
      --color-primary-dark-7:    #FDE8D5;
      --color-primary-light-1:   #F06428;
      --color-primary-light-2:   #E04D10;
      --color-primary-light-3:   #C43D00;
      --color-primary-light-4:   #A33000;
      --color-primary-light-5:   #A33000;
      --color-primary-light-6:   #852500;
      --color-primary-light-7:   #852500;
      --color-primary-alpha-10:  #F5803E19;
      --color-primary-alpha-20:  #F5803E33;
      --color-primary-alpha-30:  #F5803E4B;
      --color-primary-alpha-40:  #F5803E66;
      --color-primary-alpha-50:  #F5803E80;
      --color-primary-alpha-60:  #F5803E99;
      --color-primary-alpha-70:  #F5803EB3;
      --color-primary-alpha-80:  #F5803ECC;
      --color-primary-alpha-90:  #F5803EE1;
      --color-primary-hover:     var(--color-primary-light-1);
      --color-primary-active:    var(--color-primary-light-2);

      /* Secondary */
      --color-secondary:          var(--ns-700);
      --color-secondary-dark-1:   var(--ns-550);
      --color-secondary-dark-2:   var(--ns-500);
      --color-secondary-dark-3:   var(--ns-450);
      --color-secondary-dark-4:   var(--ns-400);
      --color-secondary-dark-5:   var(--ns-350);
      --color-secondary-dark-6:   var(--ns-300);
      --color-secondary-dark-7:   var(--ns-250);
      --color-secondary-dark-8:   var(--ns-200);
      --color-secondary-dark-9:   var(--ns-150);
      --color-secondary-dark-10:  var(--ns-100);
      --color-secondary-dark-11:  var(--ns-100);
      --color-secondary-dark-12:  var(--ns-100);
      --color-secondary-dark-13:  var(--ns-100);
      --color-secondary-light-1:  var(--ns-650);
      --color-secondary-light-2:  var(--ns-700);
      --color-secondary-light-3:  var(--ns-750);
      --color-secondary-light-4:  var(--ns-800);
      --color-secondary-alpha-10: #1D253019;
      --color-secondary-alpha-20: #1D253033;
      --color-secondary-alpha-30: #1D25304B;
      --color-secondary-alpha-40: #1D253066;
      --color-secondary-alpha-50: #1D253080;
      --color-secondary-alpha-60: #1D253099;
      --color-secondary-alpha-70: #1D2530B3;
      --color-secondary-alpha-80: #1D2530CC;
      --color-secondary-alpha-90: #1D2530E1;
      --color-secondary-hover:    var(--color-secondary-light-1);
      --color-secondary-active:   var(--color-secondary-light-2);

      /* Semantic colors */
      --color-red:          #b91c1c;
      --color-orange:       #F5803E;
      --color-yellow:       #ca8a04;
      --color-olive:        #91a313;
      --color-green:        #15803d;
      --color-teal:         #0d9488;
      --color-blue:         #2563eb;
      --color-violet:       #7c3aed;
      --color-purple:       #9333ea;
      --color-pink:         #db2777;
      --color-brown:        #a47252;
      --color-grey:         var(--ns-500);
      --color-black:        #111827;
      --color-red-light:    #FF5370;
      --color-orange-light: #F5803E;
      --color-yellow-light: #FFB454;
      --color-olive-light:  #839311;
      --color-green-light:  #AAD94C;
      --color-teal-light:   #39BAE6;
      --color-blue-light:   #82AAFF;
      --color-violet-light: #C792EA;
      --color-purple-light: #C792EA;
      --color-pink-light:   #ec4899;
      --color-brown-light:  #94674a;
      --color-grey-light:   var(--ns-300);
      --color-black-light:  #1f2937;
      --color-red-dark-1:   #a71919;
      --color-orange-dark-1:#d34f0b;
      --color-yellow-dark-1:#b67c04;
      --color-green-dark-1: #137337;
      --color-teal-dark-1:  #0c857a;
      --color-blue-dark-1:  #1554e0;
      --color-violet-dark-1:#6a1feb;
      --color-purple-dark-1:#8519e7;
      --color-red-dark-2:   #941616;
      --color-orange-dark-2:#bb460a;
      --color-yellow-dark-2:#ca8a04;
      --color-green-dark-2: #15803d;
      --color-teal-dark-2:  #0a766d;
      --color-blue-dark-2:  #2563eb;
      --color-violet-dark-2:#5c14d8;
      --color-purple-dark-2:#7c3aed;
      --color-black-dark-1: #0f1623;
      --color-black-dark-2: #111827;

      /* Console / terminal */
      --color-console-fg:           #eeeff2;
      --color-console-fg-subtle:    #959cab;
      --color-console-bg:           var(--ns-650);
      --color-console-border:       var(--ns-500);
      --color-console-hover-bg:     #ffffff16;
      --color-console-active-bg:    var(--ns-450);
      --color-console-menu-bg:      var(--ns-500);
      --color-console-menu-border:  var(--ns-400);
      --color-ansi-black:           #1d2328;
      --color-ansi-red:             #FF5370;
      --color-ansi-green:           #AAD94C;
      --color-ansi-yellow:          #FFB454;
      --color-ansi-blue:            #82AAFF;
      --color-ansi-magenta:         #C792EA;
      --color-ansi-cyan:            #39BAE6;
      --color-ansi-white:           var(--color-console-fg-subtle);
      --color-ansi-bright-black:    #424851;
      --color-ansi-bright-red:      #FF5370;
      --color-ansi-bright-green:    #C3E88D;
      --color-ansi-bright-yellow:   #F5803E;
      --color-ansi-bright-blue:     #82AAFF;
      --color-ansi-bright-magenta:  #C792EA;
      --color-ansi-bright-cyan:     #89DDFF;
      --color-ansi-bright-white:    var(--color-console-fg);

      /* Diff */
      --color-diff-removed-word-bg:   #783030;
      --color-diff-added-word-bg:     #255c39;
      --color-diff-removed-row-bg:    #432121;
      --color-diff-moved-row-bg:      #825718;
      --color-diff-added-row-bg:      #1b3625;
      --color-diff-removed-row-border:#783030;
      --color-diff-moved-row-border:  #a67a1d;
      --color-diff-added-row-border:  #255c39;
      --color-diff-inactive:          var(--ns-650);

      /* Status */
      --color-error-border:     #783030;
      --color-error-bg:         #5f2525;
      --color-error-bg-active:  #783030;
      --color-error-bg-hover:   #783030;
      --color-error-text:       #fef2f2;
      --color-success-border:   #1f6e3c;
      --color-success-bg:       #1d462c;
      --color-success-text:     #aef0c2;
      --color-warning-border:   #a67a1d;
      --color-warning-bg:       #644821;
      --color-warning-text:     #fff388;
      --color-info-border:      #2e50b0;
      --color-info-bg:          #2a396b;
      --color-info-text:        var(--ns-100);

      /* Badges */
      --color-red-badge:              #b91c1c;
      --color-red-badge-bg:           #b91c1c22;
      --color-red-badge-hover-bg:     #b91c1c44;
      --color-green-badge:            #16a34a;
      --color-green-badge-bg:         #16a34a22;
      --color-green-badge-hover-bg:   #16a34a44;
      --color-yellow-badge:           #ca8a04;
      --color-yellow-badge-bg:        #ca8a0422;
      --color-yellow-badge-hover-bg:  #ca8a0444;
      --color-orange-badge:           #F5803E;
      --color-orange-badge-bg:        #F5803E22;
      --color-orange-badge-hover-bg:  #F5803E44;

      /* Layout */
      --color-git:                #f05133;
      --color-icon-green:         #3fb950;
      --color-icon-red:           #f85149;
      --color-icon-purple:        #C792EA;
      --color-gold:               #b1983b;
      --color-white:              #ffffff;
      --color-pure-black:         #000000;
      --color-body:               var(--ns-850);
      --color-box-header:         var(--ns-700);
      --color-box-body:           var(--ns-750);
      --color-box-body-highlight: var(--ns-650);
      --color-text-dark:          #fff;
      --color-text:               var(--ns-100);
      --color-text-light:         var(--ns-150);
      --color-text-light-1:       var(--ns-150);
      --color-text-light-2:       var(--ns-200);
      --color-text-light-3:       var(--ns-200);
      --color-footer:             var(--ns-900);
      --color-timeline:           var(--ns-650);
      --color-input-text:         var(--ns-100);
      --color-input-background:   var(--ns-650);
      --color-input-toggle-background: var(--ns-650);
      --color-input-border:       var(--ns-550);
      --color-input-border-hover: var(--ns-450);
      --color-header-wrapper:     var(--ns-900);
      --color-header-wrapper-transparent: #0A0C1200;
      --color-light:              #00000028;
      --color-light-border:       #ffffff28;
      --color-hover:              var(--ns-600);
      --color-active:             var(--ns-650);
      --color-menu:               var(--ns-700);
      --color-card:               var(--ns-700);
      --color-markup-table-row:   #ffffff06;
      --color-markup-code-block:  var(--ns-800);
      --color-markup-code-inline: var(--ns-850);
      --color-button:             var(--ns-600);
      --color-code-bg:            var(--ns-750);
      --color-shadow:             #00000060;
      --color-secondary-bg:       var(--ns-700);
      --color-text-focus:         #fff;
      --color-expand-button:      var(--ns-550);
      --color-placeholder-text:   var(--color-text-light-3);
      --color-editor-line-highlight: var(--ns-700);
      --color-project-board-bg:   var(--color-secondary-light-3);
      --color-project-board-dark-label: var(--color-text-light-3);
      --color-caret:              var(--color-text);
      --color-reaction-bg:        #ffffff12;
      --color-reaction-active-bg: var(--color-primary-alpha-30);
      --color-reaction-hover-bg:  var(--color-primary-alpha-40);
      --color-tooltip-text:       #ffffff;
      --color-tooltip-bg:         #000000f0;
      --color-nav-bg:             var(--ns-900);
      --color-nav-hover-bg:       var(--ns-600);
      --color-nav-text:           var(--color-text);
      --color-secondary-nav-bg:   var(--color-body);
      --color-label-text:         #fff;
      --color-label-bg:           var(--ns-600);
      --color-label-hover-bg:     var(--ns-550);
      --color-label-active-bg:    var(--ns-500);
      --color-label-bg-alt:       var(--ns-550);
      --color-accent:             var(--color-primary-light-1);
      --color-small-accent:       var(--color-primary-light-5);
      --color-highlight-fg:       var(--color-primary-light-4);
      --color-highlight-bg:       var(--color-primary-alpha-20);
      --color-overlay-backdrop:   #080808c0;
      --checkerboard-color-1:     #474747;
      --checkerboard-color-2:     #313131;

      accent-color: var(--color-accent);
      color-scheme: dark;
    }

    * { font-family: 'Google Sans Flex', system-ui, sans-serif !important; }
    code, pre, kbd, .mono { font-family: 'Maple Mono NF CN', monospace !important; }
  '';

  # Script run as root in forgejo.service ExecStartPre — creates dirs and symlinks
  # into the Nix store so they auto-update on rebuild without a separate service.
  setupAssets = pkgs.writeShellScript "forgejo-setup-assets.sh" ''
    install -d -m 755 \
      ${customDir}/public/assets/css \
      ${customDir}/public/assets/fonts \
      ${customDir}/public/assets/img
    ln -sf ${themeCSS}  ${customDir}/public/assets/css/theme-natsumikan.css
    ln -sf ${fontFile}  ${customDir}/public/assets/fonts/GoogleSansFlex-VariableFont.ttf
    ln -sf ${iconPng}   ${customDir}/public/assets/img/favicon.png
    ln -sf ${iconPng}   ${customDir}/public/assets/img/logo.png
  '';
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."forgejo/secret-key" = { owner = "forgejo"; };
  sops.secrets."forgejo/internal-token" = { owner = "forgejo"; };
  sops.secrets."forgejo/oauth2-jwt-secret" = { owner = "forgejo"; };
  sops.secrets."forgejo/runner-token" = { mode = "0444"; };
  sops.templates."forgejo-runner-env" = {
    mode = "0444";
    content = "TOKEN=${config.sops.placeholder."forgejo/runner-token"}";
  };

  services.forgejo = {
    enable = true;
    stateDir = cfg.dataDir;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    secrets = {
      security = {
        SECRET_KEY = lib.mkForce config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = lib.mkForce config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
    };
    settings = {
      server = {
        DOMAIN = cfg.publicHost;
        ROOT_URL = "https://${cfg.publicHost}";
        HTTP_PORT = cfg.port;
        SSH_PORT = 22;
        SSH_DOMAIN = config.networking.hostName;
        SSH_USER = "forgejo";
      };
      actions.ENABLED = true;
      service.DISABLE_REGISTRATION = true;
      DEFAULT.APP_NAME = "Kuroma's Vault of Code";
      ui = {
        DEFAULT_THEME = "natsumikan";
        THEMES = "gitea,arc-green,forgejo-dark,forgejo-light,forgejo-auto,natsumikan";
      };
    };
  };

  # forgejo-secrets.service only writes if files are empty — sops secrets never are,
  # so it's a no-op. Clear ReadWritePaths so it doesn't need customDir to exist first.
  systemd.services.forgejo-secrets = {
    after = [ "sops-install-secrets.service" ];
    serviceConfig.ReadWritePaths = lib.mkForce [];
  };

  # Create custom/conf dirs on ZFS after dataset is mounted (needed by forgejo-secrets)
  systemd.services.forgejo-init-dirs = {
    description = "Create Forgejo directory structure on ZFS";
    after = [ "zfs-datasets.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/install -d -m 750 -o forgejo -g forgejo ${cfg.dataDir}/custom ${cfg.dataDir}/custom/conf";
    };
  };

  systemd.services.forgejo = {
    after = [ "postgresql-setup.service" "forgejo-init-dirs.service" ];
    requires = [ "postgresql-setup.service" "forgejo-init-dirs.service" ];
    serviceConfig.ExecStartPre = lib.mkAfter [
      # Symlink theme CSS, font, and icon from Nix store — auto-updates on rebuild
      "+${setupAssets}"
      # Re-enable write on app.ini (forgejo-secrets sets it read-only after injection)
      "+${pkgs.coreutils}/bin/chmod u+w ${customDir}/conf/app.ini"
    ];
  };

  # git SSH uses system sshd on port 22 (already open on tailscale0 via networking.nix).
  # Defense-in-depth: even if a key lands in forgejo's authorized_keys without the
  # standard `command="forgejo serv …"` prefix, this Match block keeps the session
  # from being weaponized as a pivot (no port/agent forwarding, no PTY, no X11).
  # Forgejo's own SSH operations (push/pull) don't need any of these.
  services.openssh.extraConfig = ''
    Match User forgejo
      AllowAgentForwarding no
      AllowTcpForwarding no
      AllowStreamLocalForwarding no
      PermitTTY no
      X11Forwarding no
      PermitTunnel no
      GatewayPorts no
  '';

  # Actions runner — register token from https://git.kuroma.dev/-/admin/runners then add to sops
  services.gitea-actions-runner.instances.${config.networking.hostName} = {
    enable = true;
    name = config.networking.hostName;
    url = "https://${cfg.publicHost}";
    tokenFile = config.sops.templates."forgejo-runner-env".path;
    labels = [ "native:host" "ubuntu-latest:docker://ubuntu:latest" ];
    settings = {
      log.level = "warn";
      runner.capacity = 2;
      cache.enabled = false;
    };
  };
}
