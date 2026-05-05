{ ... }:
{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "users/kuroma/password" = { neededForUsers = true; };
      "users/root/password"   = { neededForUsers = true; };
      "nas/credentials"       = { };
    };
  };

  users.users.kuroma.passwordFile = "/run/secrets-for-users/users/kuroma/password";
  users.users.root.passwordFile   = "/run/secrets-for-users/users/root/password";
}
