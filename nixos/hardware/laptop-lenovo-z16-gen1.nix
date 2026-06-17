# Lenovo ThinkPad Z16 Gen 1 hardware features
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.hardware.lenovo.z16Gen1;
in
{
  options.my.hardware.lenovo.z16Gen1.enable =
    lib.mkEnableOption "Lenovo ThinkPad Z16 Gen 1 hardware support";

  config = lib.mkIf cfg.enable {
    services = {
      power-profiles-daemon.enable = true;
      fprintd.enable = true;
      tlp.enable = false;
    };

    # Pin Chrome to the Rembrandt 680M iGPU so the RX 6500M dGPU can stay
    # in D3cold on battery. Three env vars are needed because Chrome reaches
    # the GPU through three independent paths:
    #
    #   MESA_VK_DEVICE_SELECT + _FORCE_DEFAULT_DEVICE — radv's Vulkan layer.
    #     `--use-angle=vulkan` makes ANGLE enumerate every Vulkan device on
    #     startup, which would otherwise wake the dGPU out of D3cold at ~15W
    #     idle even when --render-node-override points at the iGPU.
    #   DRI_PRIME=0 — Mesa's GL/EGL/GBM picker. Forces the iGPU for
    #     VA-API video decode, GBM compositing, and any GL fallback paths
    #     ANGLE doesn't cover.
    #
    # Verified empirically: with just the MESA_VK pair the dGPU still woke
    # under video load (Twitter playback). Adding DRI_PRIME kept it
    # suspended through a 45s mixed-load test. Layered on top of the home-
    # manager overlay's commandLineArgs via symlinkJoin + makeWrapper.
    nixpkgs.overlays = [
      (final: prev: {
        google-chrome = final.symlinkJoin {
          name = "google-chrome-igpu-pinned";
          paths = [ prev.google-chrome ];
          nativeBuildInputs = [ final.makeWrapper ];
          postBuild = ''
            for bin in $out/bin/*; do
              wrapProgram "$bin" \
                --set MESA_VK_DEVICE_SELECT "1002:1681" \
                --set MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE "1" \
                --set DRI_PRIME "0"
            done
            # Rewrite .desktop Exec= lines so GNOME's launcher hits the wrapped
            # binaries. symlinkJoin leaves these as symlinks back into the
            # unwrapped package, whose Exec= points at the original /bin/ —
            # which bypasses wrapProgram and skips the env vars entirely.
            for desktop in "$out"/share/applications/*.desktop; do
              orig=$(readlink -f "$desktop")
              rm "$desktop"
              sed "s|${prev.google-chrome}/bin/|$out/bin/|g" "$orig" > "$desktop"
            done
          '';
        };
      })
    ];

    # ath11k/WCN6855 WiFi tweaks
    networking.networkmanager.wifi.powersave = false;

    # Pin all wifi connections to the 5 GHz band. WCN6855's 6 GHz (WiFi 6E)
    # path on ath11k is unstable — band steering onto 6 GHz produces marginal
    # links and contributed to the post-resume crashes. "a" means 5 GHz only
    # (excludes both 2.4 GHz and 6 GHz); NM's band selector has no
    # "everything except 6 GHz" option.
    networking.networkmanager.settings.connection."wifi.band" = "a";

    # Use ethernet frame mode for better throughput and set regulatory domain
    boot.extraModprobeConfig = ''
      options ath11k frame_mode=2
      options cfg80211 ieee80211_regdom=US
    '';

    # Reload ath11k module on resume to fix WiFi after sleep
    # The WCN6855 firmware often crashes (MHI_CB_EE_RDDM) or fails to init DP
    # rings (ENOMEM) after suspend. A full PCI device reset is needed to free
    # stale DMA buffers before reloading the module.
    systemd.services.ath11k-reload-on-resume = {
      description = "Reload ath11k WiFi module after resume";
      after = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
      };
      path = [
        pkgs.kmod
        pkgs.pciutils
        pkgs.coreutils
      ];
      script = ''
        # Find the ath11k PCI device
        ATH_DEV=$(basename $(readlink /sys/module/ath11k_pci/drivers/pci:ath11k_pci/0000:* 2>/dev/null) 2>/dev/null)

        # Unload the driver
        modprobe -r ath11k_pci || true
        sleep 2

        # If we found the device, do a full PCI remove + rescan to reset DMA state
        if [ -n "$ATH_DEV" ] && [ -e "/sys/bus/pci/devices/$ATH_DEV" ]; then
          echo 1 > "/sys/bus/pci/devices/$ATH_DEV/remove"
          sleep 1
          echo 1 > /sys/bus/pci/rescan
          sleep 2
        fi

        # Reload the driver
        modprobe ath11k_pci
      '';
    };
  };
}
