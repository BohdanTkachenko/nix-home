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
            ./nixos/hardware/laptop-lenovo-z16-gen1.nix
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
        my.hardware.lenovo.z16Gen1.enable = true;
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

      personalPc = mkNixos (
        { lib, ... }:
        {
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

            # Disable scatter-gather display buffers. Navi 31 has a kernel-level
            # TLB / DMA-fence bug where freeing SG display buffers under
            # contention silently locks the GPU's MMU. The hang doesn't surface
            # as `device lost from bus` — there's no log at all; the kernel
            # stalls in the amdgpu fence path before printk can flush, fans go
            # to BIOS failsafe, hard reset only. Reproducible by closing a
            # heavy WebGL tab (Unifi admin) in Chrome and during DXVK workloads
            # like Overwatch under Wine. Costs a small amount of VRAM
            # bandwidth — display buffers go through a contiguous CMA path
            # instead of SG/IOMMU. Worth it for stability.
            "amdgpu.sg_display=0"

            # Disable the VCN (Video Core Next) and JPEG IP blocks on Navi 31.
            # NOTE on the mask: `amdgpu.ip_block_mask` indexes by the GPU's
            # per-device IP-block array position, NOT by AMD_IP_BLOCK_TYPE
            # enum. On Navi 31 the array is: 0=common, 1=gmc, 2=ih, 3=psp,
            # 4=smc, 5=dm, 6=gfx, 7=sdma, 8=vcn, 9=jpeg, 10=mes. So clearing
            # bits 8 and 9 = 0xfffffcff disables VCN and JPEG (which share
            # hardware on RDNA3 — disabling one without the other tends to
            # leave the survivor in a broken state). Verified post-boot via
            # `detected ip block number 8 <vcn_v4_0_0>` in dmesg.
            #
            # Why disable: the RX 7900 XTX cascades a `device lost from bus`
            # into VCN errors (`vcn sram load failed`, `Ring vcn_unified_0
            # reset failed`) that flood the log and block recovery. Removing
            # the VCN engine cuts that noise and reduces the surface area for
            # SMU/MES wedges. Trade-off: hwaccel video decode falls back to
            # CPU/shader paths — small power/perf cost, big stability win.
            "amdgpu.ip_block_mask=0xfffffcff"

            # Disable gfxoff (the GPU's internal graphics power-gating) by
            # masking PP_GFXOFF_MASK (bit 9) out of `ppfeaturemask`. Default
            # on kernel 7.0.x is `0xfff7bfff`; clearing bit 9 → `0xfff7bdff`.
            # NOTE: there is no `amdgpu.gfxoff` module parameter — the kernel
            # silently ignores it (`unknown parameter 'gfxoff' ignored`); the
            # ppfeaturemask is the only sanctioned mechanism. Verify default
            # before bumping kernel:
            #   cat /sys/module/amdgpu/parameters/ppfeaturemask
            # On Navi 31, gfxoff exit failures correlate with `device lost
            # from bus` — first observed 2026-05-07 with the dmesg signature
            # `Failed to disable gfxoff!` repeating right after bus loss.
            # Costs ~10W idle power. Targets failure mode 1; failure mode 2
            # (MES wedge under DRM file close from Electron apps, observed
            # 2026-05-09 with 1password as the trigger) has no kernel-param
            # workaround on Navi 31 — gfx_v11 has no MES-disable fallback.
            "amdgpu.ppfeaturemask=0xfff7bdff"
          ];

          # The Marvell/Aquantia 10GbE port (enp14s0) on the X870E-CREATOR is
          # unused. Its `atlantic` driver deadlocks in `aq_nic_stop` →
          # `napi_disable_locked` during suspend when there is no carrier,
          # holding rtnl_mutex forever. Every subsequent netlink caller blocks
          # in D state, new processes can't initialize networking, and even
          # `systemd-reboot` can't kill the wedged tasks. See KNOWN_ISSUES.md.
          boot.blacklistedKernelModules = [ "atlantic" ];

          # Desktop on wall power: pin amd-pstate EPP to "performance" via udev
          # and disable power-profiles-daemon (which GNOME and the shared
          # performance module both enable). With PPD off, GNOME's
          # quick-settings power toggle disappears — it's just a UI for PPD.
          services.power-profiles-daemon.enable = lib.mkForce false;
          services.udev.extraRules = ''
            ACTION=="add|change", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/energy_performance_preference}="performance"
          '';

          # Kernel panic / oops behavior: if the GPU silent-hang ever recurs
          # despite amdgpu.sg_display=0, force the kernel to panic on oops
          # (instead of trying to limp along) and auto-reboot 10s later. This
          # gives efi_pstore a chance to write the last printk buffer to UEFI
          # variables — readable from /sys/fs/pstore on the next boot. Without
          # this, panic=0 means "hang forever" and pstore captures nothing.
          #
          # `hung_task_panic=1` extends the same auto-reboot behavior to the
          # slow-death failure mode: when the GPU dies under load, TTM kthreads
          # pile up on `dma_fence_wait` for fences that will never signal
          # (`Workqueue: ttm ttm_bo_delayed_delete`). With enough wedged
          # workers, the kernel workqueue saturates and even SSH stops
          # responding — the only sign at the seat is fans at 100% and a
          # frozen console. Observed 2026-05-09 (1password Electron app
          # closing under sustained training compute → MES wedge → SDMA reset
          # fail → `device lost from bus`). Without this sysctl, the system
          # rots into an unreachable state and only a hard reset recovers.
          # With it, the first task blocked >120s (default
          # `hung_task_timeout_secs`) panics → reboot in 10s → pstore captures
          # the trace.
          boot.kernel.sysctl = {
            "kernel.panic" = 10;
            "kernel.panic_on_oops" = 1;
            "kernel.hung_task_panic" = 1;
          };

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
        }
      );

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

      homeManagerModules.base = import ./home/profiles/base.nix;
      homeManagerModules.cli = import ./home/profiles/cli.nix;
      homeManagerModules.gui = import ./home/profiles/gui.nix;
      homeManagerModules.common =
        { config, lib, ... }:
        {
          _module.args = {
            inherit pkgs-unstable pkgs-master nix-vscode-extensions;
          };

          imports = [
            chromium-pwa-wmclass-sync.homeManagerModules.default
            direnv-instant.homeModules.direnv-instant
            sops-nix.homeManagerModules.sops
            xremap.homeManagerModules.default
            ./overlays
            ./home/hardware
            ./home/profiles/common.nix
          ];
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

      packages.${system} = rec {
        init-secureboot = pkgs.callPackage ./scripts/init-secureboot.nix { };
        rebuild = pkgs.callPackage ./scripts/rebuild.nix { };
        rebuild-boot = pkgs.callPackage ./scripts/rebuild-boot.nix { };
        update = pkgs.callPackage ./scripts/update.nix { inherit rebuild; };
        check-flake = pkgs.callPackage ./scripts/check-flake.nix { };
        show-age-pubkey = pkgs.callPackage ./scripts/show-age-pubkey.nix { };
        rekey = pkgs.callPackage ./scripts/rekey.nix { };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          asn
          gnumake
          nodejs
          python3
          inetutils
          iperf
          sops
          traceroute
          wireguard-tools

          # Custom flake commands
          self.packages.${system}.rebuild
          self.packages.${system}.rebuild-boot
          self.packages.${system}.update
          self.packages.${system}.check-flake
          self.packages.${system}.show-age-pubkey
          self.packages.${system}.rekey
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
                self.homeManagerModules.work
                {
                  nixpkgs.config.allowUnfree = true;
                  home.username = "bohdant";
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
