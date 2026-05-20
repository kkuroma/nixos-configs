{ config, lib, pkgs, ... }:
let
  customDir = "${config.services.forgejo.stateDir}/custom";
  fontFile = ../config/fonts/GoogleSansFlex-VariableFont.ttf;

  # Natsumikan dark palette CSS override + Google Sans Flex (self-hosted via /-/custom/fonts/)
  footerTemplate = pkgs.writeText "forgejo-footer.tmpl" ''
    <style>
    @font-face {
      font-family: 'Google Sans Flex';
      src: url('/-/custom/fonts/GoogleSansFlex-VariableFont.ttf') format('truetype');
      font-weight: 100 900;
      font-style: normal;
      font-display: swap;
    }
    html[data-theme="forgejo-dark"],
    html[data-theme="gitea-dark"] {
      --color-body:            #0D1017;
      --color-secondary-bg:    #171D26;
      --color-nav-bg:          #0D1017;
      --color-sidebar-bg:      #171D26;
      --color-header-bg:       #0D1017;
      --color-menu-bg:         #171D26;
      --color-input-bg:        #171D26;
      --color-card:            #171D26;
      --color-border:          #242C3A;
      --color-text:            #D1D1C7;
      --color-text-dark:       #E8E8E4;
      --color-text-light-1:    #B0B8C1;
      --color-text-light-2:    #8E959E;
      --color-text-light-3:    #6E757E;
      --color-primary:         #F5803E;
      --color-primary-light-1: #F7904F;
      --color-primary-light-2: #F8A060;
      --color-primary-light-3: #F9B070;
      --color-primary-light-4: #FAC090;
      --color-primary-light-5: #FBD0B0;
      --color-primary-light-6: #FDE0D0;
      --color-primary-dark-1:  #E06A28;
      --color-primary-dark-2:  #CC5510;
      --color-primary-dark-3:  #B84400;
      --color-red:             #FF5370;
      --color-green:           #AAD94C;
      --color-yellow:          #FFB454;
      --color-blue:            #82AAFF;
      --color-orange:          #F5803E;
      --color-teal:            #39BAE6;
      --color-purple:          #C792EA;
      --color-info:            #39BAE6;
      --color-success:         #AAD94C;
      --color-warning:         #FFB454;
      --color-danger:          #FF5370;
      --color-diff-removed-word-bg: rgba(255, 83, 112, 0.3);
      --color-diff-added-word-bg:   rgba(170, 217, 76, 0.3);
      --color-diff-removed-bg:      rgba(255, 83, 112, 0.08);
      --color-diff-added-bg:        rgba(170, 217, 76, 0.08);
    }
    * { font-family: 'Google Sans Flex', system-ui, sans-serif !important; }
    code, pre, kbd, .mono { font-family: 'Maple Mono NF CN', monospace !important; }
    </style>
  '';
in
{
  sops.secrets."forgejo/secret-key" = { owner = "forgejo"; };
  sops.secrets."forgejo/internal-token" = { owner = "forgejo"; };
  sops.secrets."forgejo/oauth2-jwt-secret" = { owner = "forgejo"; };
  sops.secrets."forgejo/runner-token" = { owner = "gitea-runner-metatron"; mode = "0440"; };

  services.caddy.virtualHosts = {
    "forgejo.${config.networking.hostName}".extraConfig = "tls internal\nreverse_proxy localhost:1412";
    "http://git.kuroma.dev".extraConfig = "reverse_proxy localhost:1412";
  };

  services.forgejo = {
    enable = true;
    stateDir = "/tank/services/forgejo";
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
        DOMAIN = "git.kuroma.dev";
        ROOT_URL = "https://git.kuroma.dev";
        HTTP_PORT = 1412;
        SSH_PORT = 2222;
        SSH_DOMAIN = "metatron";
      };
      actions.ENABLED = true;
      service.DISABLE_REGISTRATION = true;
      ui.DEFAULT_THEME = "forgejo-dark";
    };
  };

  # forgejo-secrets.service only writes if files are empty — sops secrets never are,
  # so it's a no-op. Clear ReadWritePaths so it doesn't need customDir to exist first.
  systemd.services.forgejo-secrets = {
    after = [ "sops-install-secrets.service" ];
    serviceConfig.ReadWritePaths = lib.mkForce [];
  };

  # Create custom/conf dirs on ZFS after dataset is mounted
  systemd.services.forgejo-init-dirs = {
    description = "Create Forgejo directory structure on ZFS";
    after = [ "zfs-datasets.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/install -d -m 750 -o forgejo -g forgejo /tank/services/forgejo/custom /tank/services/forgejo/custom/conf";
    };
  };

  # Deploy Natsumikan theme + font CSS via custom footer template
  systemd.services.forgejo-custom-theme = {
    description = "Deploy Forgejo custom theme files";
    after = [ "forgejo-init-dirs.service" ];
    requires = [ "forgejo-init-dirs.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "forgejo-custom-theme.sh" ''
        ${pkgs.coreutils}/bin/install -d -m 750 -o forgejo -g forgejo \
          ${customDir}/templates \
          ${customDir}/templates/custom \
          ${customDir}/public \
          ${customDir}/public/fonts
        ${pkgs.coreutils}/bin/install -m 644 -o forgejo -g forgejo \
          ${footerTemplate} \
          ${customDir}/templates/custom/footer.tmpl
        ${pkgs.coreutils}/bin/install -m 644 -o forgejo -g forgejo \
          ${fontFile} \
          ${customDir}/public/fonts/GoogleSansFlex-VariableFont.ttf
      '';
    };
  };

  systemd.services.forgejo = {
    after = [ "zfs-datasets.service" "postgresql-setup.service" "forgejo-init-dirs.service" "forgejo-custom-theme.service" ];
    requires = [ "zfs-datasets.service" "postgresql-setup.service" "forgejo-init-dirs.service" ];
    # Forgejo 11.x writes to app.ini on startup (oauth2 init); the pre-start sets
    # it read-only after injecting secrets, so we re-enable writes before ExecStart.
    serviceConfig.ExecStartPre = lib.mkAfter [
      "+${pkgs.coreutils}/bin/chmod u+w /tank/services/forgejo/custom/conf/app.ini"
    ];
  };

  # git SSH on port 2222, tailscale only
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2222 ];

  # Actions runner — register token from https://git.kuroma.dev/-/admin/runners then add to sops
  services.gitea-actions-runner.instances."metatron" = {
    enable = true;
    name = "metatron";
    url = "https://git.kuroma.dev";
    tokenFile = config.sops.secrets."forgejo/runner-token".path;
    settings = {
      log.level = "warn";
      runner = {
        # "native:host" runs jobs directly on metatron; add docker:// labels later for containerized jobs
        labels = [ "native:host" "ubuntu-latest:docker://ubuntu:latest" ];
        capacity = 2;
      };
      cache.enabled = false;
    };
  };
}
