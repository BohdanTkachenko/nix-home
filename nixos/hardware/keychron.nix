{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ keychron-udev-rules ];

  # Remove power-switch tag from Keychron keyboard to prevent spurious
  # sleep key events during USB re-enumeration after resume from suspend
  services.udev.extraRules = ''
    # Allow hidraw access for Keychron configuration tools (e.g. WebHID launcher)
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"

    SUBSYSTEM=="input", ATTR{name}=="Keychron Keychron Ultra-Link 8K Keyboard", TAG-="power-switch"
  '';
}
