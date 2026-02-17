# ZSA Moonlander - prevent spurious power key events on resume
{
  # Disable power key handling for Moonlander's System Control interface
  # This prevents spurious power button events when USB reinitializes after resume
  services.udev.extraRules = ''
    # ZSA Moonlander - allow hidraw access for configuration tools
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3297", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"

    # Remove power-switch tag from Moonlander System Control to prevent re-suspend on wake
    # logind watches devices tagged power-switch for sleep/power button events;
    # the Moonlander sends spurious events during USB re-enumeration after resume
    SUBSYSTEM=="input", ATTR{name}=="ZSA Technology Labs Moonlander Mark I System Control", TAG-="power-switch"
    SUBSYSTEM=="input", ATTR{name}=="ZSA Technology Labs Moonlander Mark I", TAG-="power-switch"
  '';
}
