{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manage-flatpaks = {
      url = "path:./pkgs/manage-flatpaks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      manage-flatpaks,
      xremap,
      ...
    }:
    {
      homeConfigurations."dan" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          xremap.homeManagerModules.default
          manage-flatpaks.homeManagerModules.default
          ./home.nix
        ];
      };
    };
}
