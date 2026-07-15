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

    nixvim.url = "github:nix-community/nixvim";

    nix-flatpak.url = "github:gmodena/nix-flatpak"; # declarative flatpak

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscodium-server = {
      url = "github:unicap/nixos-vscodium-server";
      flake = false; # its outputs eval x86_64-darwin, dropped in nixpkgs 26.11
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    llama-router = {
      url = "git+https://git.kuroma.dev/kkuroma/llama-router";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, noctalia, sops-nix, nixos-hardware, ... }@inputs:
  let
    system = "x86_64-linux";
    username = "kuroma";
    lib = nixpkgs.lib;
    metatronIP = "100.107.220.115";
    zaphkielIP = "100.91.235.104";
    razielIP = "100.79.72.120";

    # per machine profiles including hardware, system fonts, and video enc/dec
    machines = {
      zaphkiel = {
        # zen: performance-tuned like xanmod, tracks mainline, has ZFS packaged
        kernelPackages = pkgs: pkgs.linuxPackages;
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 10; };
        nvenc = true;
        hwdec = "nvdec-copy";
        displays = [ # get parsed to niri
          {
            output = "HDMI-A-1";
            mode = "1920x1080@144.001";
            y = 1000;
            x = 2560;
            # transform = "90";
            # defaultColumnWidth = "proportion 1.0";
          }
          {
            output = "DP-3";
            mode = "2560x1440@143.972";
            x = 0;
            y = 0;
          }
        ];
      };
      raziel = {
        kernelPackages = pkgs: pkgs.linuxPackages;
        fonts = { uiSize = 12; monoSize = 12; ghosttyFontSize = 11; };
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

    # Per-host wiring lives here; configuration.nix handles system, hosts/<name>/home.nix
    # (optional) handles host-specific HM extras.
    mkHost = name: { extraModules ? [] }: lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username metatronIP zaphkielIP razielIP; machineConfig = machines.${name}; };
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        inputs.llama-router.nixosModules.default
        (./hosts + "/${name}/configuration.nix")
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = hmExtraArgs machines.${name};
            users.${username}.imports =
              [ ./home ]
              ++ lib.optional (builtins.pathExists (./hosts + "/${name}/home.nix"))
                              (./hosts + "/${name}/home.nix");
          };
        }
      ] ++ extraModules;
    };
  in {
    nixosConfigurations = {
      zaphkiel = mkHost "zaphkiel" { };
      metatron = mkHost "metatron" { };
      raziel   = mkHost "raziel"   {
        extraModules = [ nixos-hardware.nixosModules.framework-amd-ai-300-series ];
      };
    };
  };
}
