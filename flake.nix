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

    millennium = {
      url = "github:SteamClientHomebrew/Millennium/e2c66a276e579ee73c5151b01897bf63503aa12c?dir=packages/nix";
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

    # Per-machine hardware profile. kernelPackages is a function pkgs: pkgs.<set>
    # so it uses the NixOS-managed pkgs (with overlays/config) rather than a
    # separate import. displays is structured data rendered to KDL by home/niri.nix.
    machines = {
      zaphkiel = {
        kernelPackages = pkgs: pkgs.linuxKernel.packages.linux_xanmod_latest;
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 10; };
        displays = [
          {
            output = "HDMI-A-1";
            mode = "1920x1080@119.879";
            x = 0; y = 0;
            transform = "90";
            defaultColumnWidth = "proportion 1.0";
          }
          {
            output = "HDMI-A-2";
            mode = "1920x1080@119.879";
            x = 1080; y = 700;
          }
        ];
      };
      raziel = {
        # linuxPackages_latest: mainline kernel, in Hydra cache (no local compilation),
        # better AMD power management support than xanmod on battery.
        kernelPackages = pkgs: pkgs.linuxPackages_latest;
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 9; };
        displays = [
          {
            output = "eDP-1";
            mode = "2880x1920@120.000";
            x = 0; y = 0;
            scale = 1.66;
          }
        ];
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
      specialArgs = { inherit inputs username; machineConfig = machines.zaphkiel; };
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
            users.${username} = { imports = [ inputs.nixvim.homeModules.nixvim ./home/kuroma.nix ./hosts/zaphkiel/home.nix ]; };
          };
        })
      ];
    };

    nixosConfigurations.raziel = lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username; machineConfig = machines.raziel; };
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
            users.${username} = { imports = [ inputs.nixvim.homeModules.nixvim ./home/kuroma.nix ./hosts/raziel/home.nix ]; };
          };
        })
      ];
    };
  };
}
