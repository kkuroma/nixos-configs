{ config, lib, pkgs, ... }:
let
  cfg = config.host.services.beszel or null;
  # PocketBase data dir: DefaultDataDir "beszel_data" relative to the hub unit's WorkingDirectory
  hubKey = "/var/lib/beszel-hub/beszel_data/id_ed25519";
  agentKey = "/run/beszel/agent-key.pub";
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."beszel/email" = { };
  sops.secrets."beszel/password" = { };

  # Seeds the first admin account (superuser + app user) on a fresh hub; ignored once it exists
  sops.templates."beszel-hub-env".content = ''
    USER_EMAIL=${config.sops.placeholder."beszel/email"}
    USER_PASSWORD=${config.sops.placeholder."beszel/password"}
  '';

  services.beszel = {
    hub = {
      enable = true;
      port = cfg.port;
      environmentFile = config.sops.templates."beszel-hub-env".path;
    };

    # Loopback agent: each hub monitors its own machine. Pairing is automated
    # by the two oneshots below — no GUI steps
    agent = {
      enable = true;
      environment = {
        LISTEN = "127.0.0.1:45876";
        KEY_FILE = agentKey;
      };
    };
  };

  # The hub only writes its private key; derive the public half for the agent
  systemd.services.beszel-agent-key = {
    description = "Derive beszel hub public key for the local agent";
    wantedBy = [ "multi-user.target" ];
    requires = [ "beszel-hub.service" ];
    after = [ "beszel-hub.service" ];
    before = [ "beszel-agent.service" ];
    requiredBy = [ "beszel-agent.service" ];
    path = [ pkgs.openssh ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "beszel";
      RuntimeDirectoryPreserve = true;
      TimeoutStartSec = "5min";
    };
    script = ''
      until [ -s ${hubKey} ]; do sleep 1; done
      ssh-keygen -y -f ${hubKey} > ${agentKey}
      chmod 0644 ${agentKey}
    '';
  };

  # The hub UI's "Add System" is just a record in the PocketBase systems
  # collection — create it via the REST API instead. Idempotent; coupled to
  # beszel's collection schema (name/host/port text, users relation, status
  # select), so a major beszel upgrade may need this revisited
  systemd.services.beszel-register-localhost = {
    description = "Register the localhost agent in the beszel hub";
    wantedBy = [ "multi-user.target" ];
    requires = [ "beszel-hub.service" ];
    after = [ "beszel-hub.service" "sops-install-secrets.service" ];
    path = [ pkgs.curl pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "5min";
    };
    script = ''
      set -euo pipefail
      base=http://127.0.0.1:${toString cfg.port}

      until curl -fs "$base/api/health" >/dev/null; do sleep 2; done

      auth=$(jq -n \
        --arg id "$(cat ${config.sops.secrets."beszel/email".path})" \
        --arg pw "$(cat ${config.sops.secrets."beszel/password".path})" \
        '{identity: $id, password: $pw}' |
        curl -fs "$base/api/collections/users/auth-with-password" \
          -H 'Content-Type: application/json' -d @-)
      token=$(jq -r .token <<<"$auth")
      uid=$(jq -r .record.id <<<"$auth")

      count=$(curl -fs -G "$base/api/collections/systems/records" \
        --data-urlencode "filter=(host='127.0.0.1')" \
        -H "Authorization: $token" | jq -r .totalItems)

      if [ "$count" = "0" ]; then
        jq -n --arg name ${config.networking.hostName} --arg uid "$uid" \
          '{name: $name, host: "127.0.0.1", port: "45876", users: [$uid], status: "pending"}' |
          curl -fs "$base/api/collections/systems/records" \
            -H 'Content-Type: application/json' -H "Authorization: $token" -d @- >/dev/null
        echo "registered localhost system"
      else
        echo "localhost system already registered"
      fi
    '';
  };
}
