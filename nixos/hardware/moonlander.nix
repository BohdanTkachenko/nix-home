# ZSA Moonlander keyboard support
{
  # Enable full ZSA udev rules (hidraw access, DFU flashing, etc.)
  hardware.keyboard.zsa.enable = true;

  # Remove power-switch tag from Moonlander System Control to prevent re-suspend on wake
  # logind watches devices tagged power-switch for sleep/power button events;
  # the Moonlander sends spurious events during USB re-enumeration after resume
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTR{name}=="ZSA Technology Labs Moonlander Mark I System Control", TAG-="power-switch"
    SUBSYSTEM=="input", ATTR{name}=="ZSA Technology Labs Moonlander Mark I", TAG-="power-switch"
  '';
}
