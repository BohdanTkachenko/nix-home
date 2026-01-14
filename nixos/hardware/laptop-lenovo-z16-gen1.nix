# Laptop-specific hardware features
{ pkgs, ... }:
{
  services = {
    power-profiles-daemon.enable = true;
    fprintd.enable = true;
    tlp.enable = false;
  };

  # ath11k/WCN6855 WiFi fixes for power management and suspend/resume issues
  # The chip has known bugs causing disconnections and firmware crashes (MHI_CB_EE_RDDM)
  networking.networkmanager.wifi.powersave = false;

  # Disable power saving at the driver level
  boot.extraModprobeConfig = ''
    options ath11k_pci power_save=0
  '';

  # Reload ath11k module on resume to fix WiFi after sleep
  # The driver often fails to reinitialize properly after suspend
  systemd.services.ath11k-reload-on-resume = {
    description = "Reload ath11k WiFi module after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.kmod}/bin/modprobe -r ath11k_pci
      sleep 1
      ${pkgs.kmod}/bin/modprobe ath11k_pci
    '';
  };
}