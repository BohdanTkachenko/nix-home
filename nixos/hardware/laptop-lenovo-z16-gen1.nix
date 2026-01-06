# Laptop-specific hardware features
{ ... }:
{
  services = {
    power-profiles-daemon.enable = true;
    fprintd.enable = true;
    tlp.enable = false;
  };

  # Disabled due to ath11k driver bugs causing frequent disconnections and
  # firmware crashes (MHI_CB_EE_RDDM). The WCN6855 chip has known power
  # management issues that manifest as "Connection to AP lost" every few minutes.
  #
  # If issues persist, try disabling power saving at the driver level:
  #   boot.extraModprobeConfig = ''
  #     options ath11k_pci power_save=0
  #   '';
  networking.networkmanager.wifi.powersave = false;
}