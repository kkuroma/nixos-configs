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

    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
    vscodium-server.url = "github:unicap/nixos-vscodium-server";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, disko, home-manager, noctalia, sops-nix, nixos-hardware, ... }@inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.zaphkiel = lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/zaphkiel/configuration.nix
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {
              inherit inputs;
              niriParts = [
                ./config/niri/noctalia.kdl
                ./config/niri/keybinds.kdl
              ];
            };
            users.kuroma = { imports = [ inputs.nixvim.homeModules.nixvim ./home/kuroma.nix ./hosts/zaphkiel/home.nix ]; };
          };
        }
      ];
    };

    nixosConfigurations.raziel = lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        nixos-hardware.nixosModules.framework-amd-ai-300-series
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/raziel/configuration.nix
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {
              inherit inputs;
              niriParts = [
                ./config/niri/noctalia.kdl
                ./config/niri/keybinds.kdl
              ];
            };
            users.kuroma = { imports = [ inputs.nixvim.homeModules.nixvim ./home/kuroma.nix ./hosts/raziel/home.nix ]; };
          };
        }
      ];
    };
  };
}
