{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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

    manage-flatpaks = {
      url = "path:./pkgs/manage-flatpaks";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chromium-pwa-wmclass-sync = {
      url = "path:./pkgs/chromium-pwa-wmclass-sync";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      chromium-pwa-wmclass-sync,
      home-manager,
      manage-flatpaks,
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      xremap,
      ...
    }:

    let
      bootstrap = import ./bootstrap.nix;
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      homeConfigurations = lib.genAttrs bootstrap.hosttypes (
        hostTypeName:
        let
          features = {
            xremap = (hostTypeName == "lenovo-z16");
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            pkgs-unstable = pkgs-unstable;
            features = features;
            bootstrap = bootstrap;
          };
          modules = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            manage-flatpaks.homeManagerModules.default
            sops-nix.homeManagerModules.sops
            ./home.nix
          ]
          ++ (lib.optional features.xremap xremap.homeManagerModules.default);
        }
      );
    };
}
