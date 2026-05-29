{
  description = "my nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscodium-server = {
      url = "github:unicap/nixos-vscodium-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, disko, home-manager, noctalia, sops-nix, nixos-hardware, ... }@inputs:
  let
    system = "x86_64-linux";
    username = "kuroma";
    lib = nixpkgs.lib;
    metatronIP  = "100.107.220.115";
    zaphkielIP  = "100.91.235.104";
    razielIP    = "100.79.72.120";

    # per machine profiles including hardware, system fonts, and video enc/dec
    machines = {
      zaphkiel = {
        # zen: performance-tuned like xanmod, tracks mainline, has ZFS packaged
        kernelPackages = pkgs: pkgs.linuxPackages_zen;
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 10; };
        nvenc = true;
        hwdec = "nvdec-copy";
        displays = [ # get parsed to niri
          {
            output = "HDMI-A-1";
            mode = "1920x1080@119.879";
            x = 0;
            y = 0;
            transform = "90";
            defaultColumnWidth = "proportion 1.0";
          }
          {
            output = "HDMI-A-2";
            mode = "1920x1080@119.879";
            x = 1080;
            y = 700;
          }
        ];
      };
      raziel = {
        # linuxPackages_latest: latest kernel for security patches, perf boost only hurts battery
        kernelPackages = pkgs: pkgs.linuxPackages_latest;
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 9; };
        nvenc = false;
        hwdec = "vaapi";
        displays = [
          {
            output = "eDP-1";
            mode = "2880x1920@120.000";
            x = 0;
            y = 0;
            scale = 1.66;
          }
        ];
      };
      metatron = {
        kernelPackages = pkgs: pkgs.linuxPackages; # LTS — linuxPackages_latest breaks ZFS
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 10; };
        nvenc = true; # dGPU: 1650 for transcoding
        hwdec = "vaapi"; # iGPU
        displays = []; # leave empty let KDE handle it
      };
    };

    niriParts = [
      ./config/niri/noctalia.kdl
      ./config/niri/keybinds.kdl
    ];

    hmExtraArgs = machineConfig: {
      inherit inputs username machineConfig niriParts;
    };
  in {
    nixosConfigurations.zaphkiel = lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username metatronIP zaphkielIP razielIP; machineConfig = machines.zaphkiel; };
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/zaphkiel/configuration.nix
        ({ username, ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = hmExtraArgs machines.zaphkiel;
            users.${username} = { imports = [ inputs.nixvim.homeModules.nixvim ./home/kuroma.nix ]; };
          };
        })
      ];
    };

    nixosConfigurations.metatron = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username metatronIP zaphkielIP razielIP; machineConfig = machines.metatron; };
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/metatron/configuration.nix
        ({ username, ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = (hmExtraArgs machines.metatron) // { niriParts = []; }; # no niri
            users.${username} = {
              imports = [ ./home/kuroma-server.nix ];
              home.stateVersion = "25.11";
              programs.zsh.shellAliases = {
                matrix-add-user = "sudo register_new_matrix_user -k $(sudo cat /run/secrets/matrix/registration-secret) http://localhost:8448";
              };
              home.file.".config/zsh-prompt.zsh".source = ./config/zsh-prompt.zsh;
              programs.zsh.initContent = ''
                export TERM=xterm-256color
                source ~/.config/zsh-prompt.zsh
              '';
            };
          };
        })
      ];
    };

    nixosConfigurations.raziel = lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username metatronIP zaphkielIP razielIP; machineConfig = machines.raziel; };
      modules = [
        nixos-hardware.nixosModules.framework-amd-ai-300-series
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/raziel/configuration.nix
        ({ username, ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = hmExtraArgs machines.raziel;
            users.${username} = {
              imports = [ inputs.nixvim.homeModules.nixvim ./home/kuroma.nix ];
              # raziel-specific: lock screen before sleep via swayidle
              services.swayidle = {
                enable = true;
                extraArgs = [ "-w" ];
                events.before-sleep = "/run/current-system/sw/bin/noctalia-shell ipc --any-display call lockScreen lock";
              };
            };
          };
        })
      ];
    };
  };
}
