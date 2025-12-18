{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:BohdanTkachenko/home-manager/systemd-path-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chromium-pwa-wmclass-sync = {
      url = "path:./pkgs/chromium-pwa-wmclass-sync";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      chromium-pwa-wmclass-sync,
      disko,
      lanzaboote,
      home-manager,
      nixgl,
      nixpkgs,
      nixpkgs-unstable,
      browser-previews,
      sops-nix,
      xremap,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      mkHome =
        hostSpecificModule: isLaptop:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit nixgl pkgs-unstable;
            browser-previews-pkgs = browser-previews.packages.${system};
            isWork = true;
            isWorkPC = !isLaptop;
            isWorkLaptop = isLaptop;
          };
          modules = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            sops-nix.homeManagerModules.sops
            xremap.homeManagerModules.default
          ]
          ++ [ hostSpecificModule ];
        };

      mkNixos =
        machineModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs-unstable;
            browser-previews-pkgs = browser-previews.packages.${system};
            isWork = false;
            isWorkPC = false;
            isWorkLaptop = false;
          };
          modules = [
            sops-nix.nixosModules.sops
            xremap.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit pkgs-unstable;
                  browser-previews-pkgs = browser-previews.packages.${system};
                  nixgl = null;
                  isWork = false;
                  isWorkPC = false;
                  isWorkLaptop = false;
                };
                sharedModules = [
                  chromium-pwa-wmclass-sync.homeManagerModules.default
                  sops-nix.homeManagerModules.sops
                  xremap.homeManagerModules.default
                ];
              };
            }
            disko.nixosModules.disko
            lanzaboote.nixosModules.lanzaboote

            machineModule
          ];
        };

      mkNixosIso =
        targetConfig:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self;
            targetConfig = targetConfig;
          };
          modules = [
            disko.nixosModules.disko
            ./nixos/installer-iso.nix
          ];
        };

      personalLaptop = mkNixos ./hosts/personal-laptop.nix;
      personalPc = mkNixos ./hosts/personal-pc.nix;
    in
    {
      nixosConfigurations = {
        dan-idea = personalLaptop;
        dan-idea-iso = mkNixosIso personalLaptop;
        nyancat = personalPc;
        nyancat-iso = mkNixosIso personalPc;
      };

      homeConfigurations = {
        "bohdant@dan.nyc.corp.google.com" = mkHome ./hosts/work-pc.nix false;
        "bohdant@bohdant.roam.corp.google.com" = mkHome ./hosts/work-laptop.nix true;
      };

      packages.${system} = {
        init-secureboot = pkgs.callPackage ./scripts/init-secureboot.nix { };
      };
    };
}
