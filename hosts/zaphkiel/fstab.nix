{ ... }:
{
  fileSystems = {
    "/mnt/Vault-Academics" = {
      device  = "/dev/disk/by-uuid/c02c0849-664d-4cb9-9585-f0fcf6234c47";
      fsType  = "ext4";
      options = [ "defaults" "nofail" "x-systemd.automount" "noatime" ];
    };

    "/mnt/Vault-Entertainment" = {
      device  = "/dev/disk/by-uuid/a690716e-4b0c-4f54-b0ad-9b9b3b18f4b4";
      fsType  = "ext4";
      options = [ "defaults" "nofail" "x-systemd.automount" "noatime" ];
    };
  };
}
