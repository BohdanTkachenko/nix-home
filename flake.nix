{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-master = {
      url = "github:NixOS/nixpkgs";
    };

    # claude-code 2.1.112 — NixOS/nixpkgs#510736
    nixpkgs-claude-code = {
      url = "github:NixOS/nixpkgs/99b135bc06e4e6df5f182c5bb9d4edc639b64846";
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

    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      chromium-pwa-wmclass-sync,
      direnv-instant,
      disko,
      lanzaboote,
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-master,
      nixpkgs-claude-code,
      browser-previews,
      nix-vscode-extensions,
      sops-nix,
      xremap,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-claude-code = import nixpkgs-claude-code {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # openldap's syncreplication test (test017) is flaky upstream and
          # blocks rebuilds whenever pkgs-unstable rolls past a cache miss.
          # The test isn't load-bearing for our use of openldap as a
          # transitive dep — skip it.
          (_: prev: {
            openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
          })
        ];
      };
      pkgs-master = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      mkNixos =
        machineModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              system
              pkgs-unstable
              pkgs-master
              pkgs-claude-code
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
                    pkgs-master
                    pkgs-claude-code
                    nix-vscode-extensions
                    ;
                };
                sharedModules = [
                  chromium-pwa-wmclass-sync.homeManagerModules.default
                  direnv-instant.homeModules.direnv-instant
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
            ./nixos/hardware/gpu-amd.nix
            ./nixos/hardware/bluetooth.nix
            ./nixos/hardware/keychron.nix
            ./nixos/hardware/epos.nix
            ./nixos/hardware/moonlander.nix
            ./nixos/hardware/touchpad.nix
            ./nixos/hardware/hidpi.nix
            ./nixos/hardware/ssd.nix
            ./nixos/hydration-common.nix
            ./nixos/disk-luks-btrfs.nix
            ./nixos/installer-iso.nix

            {
              my.hardware.gpu.amd.enable = true;
              my.hardware.bluetooth.enable = true;
              my.hardware.keychron.enable = true;
              my.hardware.epos.enable = true;
              my.hardware.hidpi.enable = true;
              my.hardware.ssd.enable = true;
              my.wireguard.enable = true;
              my.hydration.enable = true;
              my.disk.enable = true;
            }

            machineModule
          ];
        };

      personalLaptop = mkNixos {
        networking.hostName = "dan-idea";

        my.hardware.cpu.amd.enable = true;
        my.hardware.touchpad.enable = true;
        my.disk.diskDevice = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NG0R703558Y";

        # Unlock all PowerPlay features (incl. overdrive). Helpful on the iGPU
        # for manual tuning via CoreCtrl; on Navi 31 desktop cards it's been
        # tied to random GPU hangs, so it stays laptop-only.
        boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

        home-manager.sharedModules = [
          {
            my.hardware.lenovo.thinkpad = {
              enable = true;
              model = "z16-gen1";
            };
            my.direnv-instant.enable = true;
            services.easyeffects.enable = true;
          }
        ];
      };

      personalPc = mkNixos {
        nixpkgs.config.permittedInsecurePackages = [
          "mbedtls-2.28.10"
        ];

        networking.hostName = "nyancat";

        my.hardware.cpu.amd.enable = true;
        my.disk.diskDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_23402H800030";

        boot.kernelParams = [
          # Disable Multi-Plane Overlay on the RX 7900 XTX (Navi 31). MPO is a
          # known source of black-screen freezes and stutters on multi-monitor
          # / mixed-refresh setups under amdgpu's DC display engine.
          "amdgpu.dcdebugmask=0x10"

          # Force PCIe link to L0 (no L1/L1.x substates). Navi 31 has a
          # long-standing bug where the GPU fails to wake from L1, surfacing
          # as `amdgpu: device lost from bus!` followed by SMU bus errors —
          # the card vanishes from PCIe and only a hard reset recovers it.
          "pcie_aspm.policy=performance"
        ];

        # The Marvell/Aquantia 10GbE port (enp14s0) on the X870E-CREATOR is
        # unused. Its `atlantic` driver deadlocks in `aq_nic_stop` →
        # `napi_disable_locked` during suspend when there is no carrier,
        # holding rtnl_mutex forever. Every subsequent netlink caller blocks
        # in D state, new processes can't initialize networking, and even
        # `systemd-reboot` can't kill the wedged tasks. See KNOWN_ISSUES.md.
        boot.blacklistedKernelModules = [ "atlantic" ];

        my.ollama.enable = true;
        my.comfyui.enable = true;
        my.comfyui.authSops = true;
        my.comfyui.dataDir = "/home/dan/ComfyUI";
        my.comfyui.uid = 1000; # dan
        my.comfyui.gid = 100; # users
        my.comfyui.extraPipPackages = [
          "onnxruntime"
          "onnxruntime-gpu"
          "insightface"
        ];

        home-manager.sharedModules = [
          {
            my.hardware.pc.enable = true;
            my.direnv-instant.enable = true;
            services.easyeffects.enable = false;
          }
        ];
      };

      mkNixosIso =
        targetConfig:
        let
          lib = nixpkgs.lib;
          flakeOutPaths =
            let
              collector =
                parent:
                map (
                  child:
                  [ child.outPath ] ++ (if child ? inputs && child.inputs != { } then (collector child) else [ ])
                ) (lib.attrValues parent.inputs);
            in
            lib.unique (lib.flatten (collector self));
        in
        mkNixos {
          imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix" ];
          my.installer-iso = {
            enable = true;
            inherit targetConfig;
          };
          isoImage.squashfsCompression = "zstd -Xcompression-level 6";
          isoImage.volumeID = lib.mkForce "NIXOS_CUSTOM";
          isoImage.storeContents = [
            targetConfig.config.system.build.toplevel
            targetConfig.config.system.build.diskoScript
            targetConfig.config.system.build.diskoScript.drvPath
            targetConfig.pkgs.stdenv.drvPath
            targetConfig.pkgs.perlPackages.ConfigIniFiles
            targetConfig.pkgs.perlPackages.FileSlurp
          ]
          ++ flakeOutPaths;
          image.fileName = lib.mkForce "nixos-dan.iso";
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
            inherit pkgs-unstable pkgs-master pkgs-claude-code nix-vscode-extensions;
          };

          imports = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            direnv-instant.homeModules.direnv-instant
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
                  pkgs-master
                  pkgs-claude-code
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
