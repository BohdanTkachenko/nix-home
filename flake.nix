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

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      chromium-pwa-wmclass-sync,
      disko,
      lanzaboote,
      home-manager,
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

      mkNixos =
        machineModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              pkgs-unstable
              nix-vscode-extensions
              ;
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
                  inherit
                    inputs
                    system
                    pkgs-unstable
                    nix-vscode-extensions
                    ;
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

            ./nixos/common.nix
            ./nixos/wireguard.nix
            ./nixos/hardware/common.nix
            ./nixos/hardware/cpu-amd.nix
            ./nixos/hardware/cpu-intel.nix
            ./nixos/hardware/gpu-amd.nix
            ./nixos/hardware/bluetooth.nix
            ./nixos/hardware/keychron.nix
            ./nixos/hardware/moonlander.nix
            ./nixos/hardware/touchpad.nix
            ./nixos/hardware/hidpi.nix
            ./nixos/hardware/ssd.nix
            ./nixos/hydration-common.nix
            ./nixos/disk-luks-btrfs.nix

            {
              my.hardware.gpu.amd.enable = true;
              my.hardware.bluetooth.enable = true;
              my.hardware.keychron.enable = true;
              my.hardware.hidpi.enable = true;
              my.hardware.ssd.enable = true;
              my.wireguard.enable = true;
              my.hydration.enable = true;
              my.disk.enable = true;
            }

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

      personalLaptop = mkNixos {
        networking.hostName = "dan-idea";

        my.hardware.cpu.amd.enable = true;
        my.hardware.touchpad.enable = true;
        my.disk.diskDevice = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NG0R703558Y";

        home-manager.sharedModules = [{
          my.hardware.lenovo.thinkpad = {
            enable = true;
            model = "z16-gen1";
          };
        }];
      };

      personalPc = mkNixos {
        nixpkgs.config.permittedInsecurePackages = [
          "mbedtls-2.28.10"
        ];

        networking.hostName = "nyancat";

        my.hardware.cpu.intel.enable = true;
        my.disk.diskDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_23402H800030";

        home-manager.sharedModules = [{
          my.hardware.pc.enable = true;
        }];
      };
    in
    {
      nixosConfigurations = {
        dan-idea = personalLaptop;
        dan-idea-iso = mkNixosIso personalLaptop;
        nyancat = personalPc;
        nyancat-iso = mkNixosIso personalPc;
      };

      homeManagerModules.default =
        { config, lib, ... }:
        {
          _module.args = {
            inherit pkgs-unstable nix-vscode-extensions;
          };

          imports = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            sops-nix.homeManagerModules.sops
            xremap.homeManagerModules.default
            ./overlays
            ./home
          ];
        };

      packages.${system} = {
        init-secureboot = pkgs.callPackage ./scripts/init-secureboot.nix { };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          asn
          gnumake
          nodejs
          python3
          just
          inetutils
          iperf
          sops
          traceroute
          wireguard-tools
        ];
      };

      checks.${system} = {
        default = import ./tests {
          inherit self pkgs;
          lib = pkgs.lib;
        };
        google-chrome-overlay = pkgs.callPackage ./tests/google-chrome-overlay.nix { };
        fix-chrome-autostart =
          pkgs.runCommand "test-fix-chrome-autostart"
            {
              nativeBuildInputs = [ pkgs.python3 ];
              FIX_CHROME_AUTOSTART_SCRIPT = ./overlays/fix-chrome-autostart.py;
            }
            ''
              python3 ${./tests/fix-chrome-autostart.py}
              touch $out
            '';
        # Verify the actual home-manager config generates correct systemd units
        home-manager-chrome-units =
          let
            workHm = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.homeManagerModules.default
                {
                  my.google.enable = true;
                  my.environment = "work";
                  home.homeDirectory = "/home/bohdant";
                  home.stateVersion = "25.11";
                }
              ];
              extraSpecialArgs = {
                inherit
                  inputs
                  system
                  pkgs-unstable
                  nix-vscode-extensions
                  ;
              };
            };
            unitDir = "${workHm.activationPackage}/home-files/.config/systemd/user";
          in
          pkgs.runCommand "test-hm-chrome-units" { } ''
            echo "Checking home-manager generates Chrome autostart fixer unit..."

            service="${unitDir}/fix-google-chrome-stable-autostart.service"
            path="${unitDir}/fix-google-chrome-stable-autostart.path"

            # Check files exist
            test -f "$service" || { echo "FAIL: $service not found"; exit 1; }
            test -f "$path" || { echo "FAIL: $path not found"; exit 1; }

            # Verify service has correct ExecStart
            grep -q "fix-chrome-autostart" "$service" || { echo "FAIL: service missing ExecStart"; exit 1; }

            # Verify path unit watches autostart directory
            grep -q "PathChanged=.*autostart" "$path" || { echo "FAIL: path not watching autostart"; exit 1; }

            # Verify path unit will be enabled (has Install section with WantedBy)
            grep -q "WantedBy=paths.target" "$path" || { echo "FAIL: path unit won't be enabled"; exit 1; }

            touch $out
          '';
      };
    };
}
