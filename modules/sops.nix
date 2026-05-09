{ ... }:
{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "nas/credentials" = { };
      "syncthing/password" = { owner = "kuroma"; };
    };
  };
}
