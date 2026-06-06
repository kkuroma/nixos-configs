{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix

    ../../parts/universal
    ../../parts/templates
    ../../parts/modules
    ../../parts/services

    ./extra
    ./homepage.nix
  ];

  networking.hostName = "zaphkiel";
  networking.hostId = "2f88bc21"; # required by ZFS

  host = {
    gpu.nvidia = true;
    desktop = "niri";
    profile = "desktop";
    features = {
      autofs = true;
      virtualization = true;
      codiumserver = true;
    };

    services = {
      adguardhome = {
        enable = true;
        port = 3000;
      };
      syncthing = { 
        enable = true;
        port = 8384;
      };
      cockpit = { 
        enable = true; 
        port = 9090;
      };
      n8n = { 
        enable = true;
        port = 5678;
        dataDir = "/Vault/n8n";
        storage = "vault";
      };
      neo4j = { 
        enable = true; 
        port = 7474; 
        dataDir = "/Vault/neo4j"; 
        storage = "vault";
      };
      sonarr = { 
        enable = true; 
        port = 8989; 
        dataDir = "/Vault/sonarr";
        storage = "vault";
      };
      radarr = { 
        enable = true; 
        port = 7878; 
        dataDir = "/Vault/radarr"; 
        storage = "vault";
      };
      llama = { 
        enable = true; 
        port = 11434; 
        storage = "vault"; 
        unit = "llama-router"; 
      };
      llama-emb = { 
        enable = true; 
        port = 11435; 
        storage = "vault"; 
        unit = "llama-embedding";
      };
      postgresql = { 
        enable = true; 
        dataDir = "/Vault/postgresql"; 
        storage = "vault"; 
      };
    };
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "vault" ];
  boot.resumeDevice = "/dev/mapper/cryptroot";
  boot.kernelParams = [
    "resume_offset=92872541"
    "zfs.zfs_arc_max=17179869184"
  ];

  # Export vault before hibernate so ZFS doesn't see a dirty pool on resume.
  # Without this, ZFS either refuses to import or corrupts in-flight transactions.
  systemd.services.zfs-export-vault-pre-hibernate = {
    description = "Export ZFS vault pool before hibernate";
    before = [ "systemd-hibernate.service" ];
    wantedBy = [ "systemd-hibernate.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/booted-system/sw/bin/zpool export vault";
      RemainAfterExit = true;
    };
  };

  # networking.firewall.allowedTCPPorts = [ add temporary ports here, was 3000 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 11435 7687 ]; # llama API + neo4j bolt (n8n/neo4j-http via caddy)

  system.stateVersion = "25.11";
}
