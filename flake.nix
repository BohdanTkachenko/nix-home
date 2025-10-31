{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:BohdanTkachenko/home-manager/systemd-path-25.05";
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

    chromium-pwa-wmclass-sync = {
      url = "path:./pkgs/chromium-pwa-wmclass-sync";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      chromium-pwa-wmclass-sync,
      home-manager,
      nixgl,
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      xremap,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      lib = nixpkgs.lib;
      mkHome =
        hostSpecificModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit nixgl pkgs-unstable;
          };
          modules = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            sops-nix.homeManagerModules.sops
            xremap.homeManagerModules.default
          ]
          ++ [ hostSpecificModule ];
        };
    in
    {
      homeConfigurations = lib.mapAttrs' (
        fileName: fileType:
        if
          lib.strings.hasSuffix ".nix" fileName
          && fileType == "regular"
          && !lib.strings.hasPrefix "_" fileName
        then
          let
            hostname = lib.strings.removeSuffix ".nix" fileName;
          in
          lib.nameValuePair hostname (mkHome (./hosts + "/${fileName}"))
        else
          lib.nameValuePair "" null
      ) (builtins.readDir ./hosts);
    };
}
