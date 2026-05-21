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

    # ath11k/WCN6855 WiFi tweaks
    networking.networkmanager.wifi.powersave = false;

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
