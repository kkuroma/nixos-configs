{ config, lib, pkgs, ... }:
lib.mkIf config.host.features.yubikey {
  services.pcscd.enable = true; # CCID for ykman oath/piv/openpgp
  services.udev.packages = [ pkgs.yubikey-personalization ];
  environment.systemPackages = [ pkgs.yubikey-manager ]; # ykman

  sops.secrets.u2f_keys.mode = "0444";
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
      authfile = config.sops.secrets.u2f_keys.path;
      # host-independent origin: one credential works on every host.
      origin = "pam://kuroma";
      appid = "pam://kuroma";
    };
  };

  # required yubikey + fprint + password. swaylock = lockscreen; login = TTY; greetd = greeter.
  security.pam.services = lib.mkMerge [
    (lib.genAttrs [ "sudo" "polkit-1" "swaylock" "login" "greetd" ] (svc: {
      u2fAuth = true;
      rules.auth.u2f.control = lib.mkForce "required";
      rules.auth.fprintd.control =
        lib.mkIf config.security.pam.services.${svc}.fprintAuth (lib.mkForce "required");
    }))
    # remote sudo via forwarded ssh-agent key (sufficient, before u2f). pam_rssh, not
    # pam_ssh_agent_auth (the latter can't parse sk-ssh-ed25519 FIDO keys).
    { sudo.rssh = true; }
  ];

  security.pam.rssh = {
    enable = true;
    settings.auth_key_file = "/etc/ssh/sudo_trusted_keys";
  };
  environment.etc."ssh/sudo_trusted_keys".source = ./sudo-trusted-keys.pub;

  # gcr-ssh-agent can't sign sk- keys; use openssh's agent (ssh-sk-helper).
  services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
  programs.ssh.startAgent = true;

  # Two-agent: default agent stays empty (local sudo = full u2f+fprint+password); FIDO keys
  # live in this second agent, forwarded out so only remote sudo authenticates by touch.
  systemd.user.services.ssh-agent-fido = {
    description = "ssh-agent holding FIDO sudo keys (forwarded out for remote sudo)";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent-fido";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent-fido";
      SuccessExitStatus = "0 2";
    };
  };

  # load keys into the FIDO agent at login (from on-disk handle: no PIN/touch until a signature).
  systemd.user.services.ssh-add-sudo-keys = {
    description = "Load FIDO sudo keys into the forwarding agent";
    after = [ "ssh-agent-fido.service" ];
    wants = [ "ssh-agent-fido.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig.Type = "oneshot";
    environment.SSH_AUTH_SOCK = "%t/ssh-agent-fido";
    script = ''
      for k in "$HOME"/.ssh/id_sudo_sk "$HOME"/.ssh/id_sudo_sk_2; do
        [ -f "$k" ] && ${pkgs.openssh}/bin/ssh-add "$k" || true
      done
    '';
  };

  # forward the FIDO agent to our hosts so plain `ssh` carries keys for remote sudo (uid 1000 = kuroma).
  programs.ssh.extraConfig = ''
    Host raziel zaphkiel metatron
      ForwardAgent /run/user/1000/ssh-agent-fido
  '';
}
