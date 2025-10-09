{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
      xremap,
      ...
    }:

    let
      chezmoiData = import ./chezmoi-data.nix;

      system = "x86_64-linux";

      lib = nixpkgs.lib;
    in
    {
      homeConfigurations = lib.genAttrs chezmoiData.hosttypes (
        hostTypeName:
        let
          features = {
            xremap = (hostTypeName == "lenovo-z16");
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            features = features;
            chezmoiData = chezmoiData;
          };
          modules = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            manage-flatpaks.homeManagerModules.default
            ./home.nix
          ]
          ++ (lib.optional features.xremap xremap.homeManagerModules.default);
        }
      );
    };
}
