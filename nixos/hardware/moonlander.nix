# ZSA Moonlander - prevent spurious power key events on resume
{
  # Disable power key handling for Moonlander's System Control interface
  # This prevents spurious power button events when USB reinitializes after resume
  services.udev.extraRules = ''
    # ZSA Moonlander - allow hidraw access for configuration tools
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3297", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"

    # Disable power key from Moonlander System Control to prevent re-suspend on wake
    SUBSYSTEM=="input", ATTRS{idVendor}=="3297", ATTRS{name}=="*System Control*", ENV{LIBINPUT_IGNORE_DEVICE}="1", ENV{ID_INPUT_KEY}="0"
  '';
}
