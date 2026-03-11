{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ keychron-udev-rules ];

  # Allow hidraw access for Keychron configuration tools (e.g. WebHID launcher)
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';
}
