{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ keychron-udev-rules ];

  # Remove power-switch tag from Keychron keyboard to prevent spurious
  # sleep key events during USB re-enumeration after resume from suspend
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTR{name}=="Keychron Keychron Ultra-Link 8K Keyboard", TAG-="power-switch"
  '';
}
