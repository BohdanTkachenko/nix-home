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

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      url = "github:BohdanTkachenko/chromium-pwa-wmclass-sync";
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
      nix-vscode-extensions,
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
            inherit nixgl pkgs-unstable nix-vscode-extensions;
            browser-previews-pkgs = browser-previews.packages.${system};
            isWork = true;
            isWorkPC = !isLaptop;
            isWorkLaptop = isLaptop;
          };
          modules = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            sops-nix.homeManagerModules.sops
            xremap.homeManagerModules.default
            ./overlays
            hostSpecificModule
          ];
        };

      mkNixos =
        machineModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs-unstable nix-vscode-extensions;
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
                  inherit pkgs-unstable nix-vscode-extensions;
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

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          gnumake
          sops
        ];
      };

      checks.${system} = {
        default = import ./tests {
          inherit self pkgs;
          lib = pkgs.lib;
        };
        google-chrome-overlay = pkgs.callPackage ./tests/google-chrome-overlay.nix { };
        fix-chrome-autostart = pkgs.runCommand "test-fix-chrome-autostart" {
          nativeBuildInputs = [ pkgs.python3 ];
          FIX_CHROME_AUTOSTART_SCRIPT = ./overlays/fix-chrome-autostart.py;
        } ''
          python3 ${./tests/fix-chrome-autostart.py}
          touch $out
        '';
        # Verify the actual home-manager config generates correct systemd units
        home-manager-chrome-units =
          let
            hm = self.homeConfigurations."bohdant@dan.nyc.corp.google.com";
            unitDir = "${hm.activationPackage}/home-files/.config/systemd/user";
          in
          pkgs.runCommand "test-hm-chrome-units" { } ''
            echo "Checking home-manager generates Chrome autostart fixer units..."

            for variant in google-chrome-stable google-chrome-beta; do
              echo "Checking $variant..."

              service="${unitDir}/fix-''${variant}-autostart.service"
              path="${unitDir}/fix-''${variant}-autostart.path"

              # Check files exist
              test -f "$service" || { echo "FAIL: $service not found"; exit 1; }
              test -f "$path" || { echo "FAIL: $path not found"; exit 1; }

              # Verify service has correct ExecStart
              grep -q "fix-chrome-autostart" "$service" || { echo "FAIL: service missing ExecStart"; exit 1; }

              # Verify path unit watches autostart directory
              grep -q "PathChanged=.*autostart" "$path" || { echo "FAIL: path not watching autostart"; exit 1; }

              # Verify path unit will be enabled (has Install section with WantedBy)
              grep -q "WantedBy=paths.target" "$path" || { echo "FAIL: path unit won't be enabled"; exit 1; }

              echo "PASS: $variant"
            done

            echo "All home-manager unit checks passed!"
            touch $out
          '';
      };
    };
}
