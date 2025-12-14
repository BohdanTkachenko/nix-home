# Moonlander Keyboard Causing Immediate Re-suspend After Wake

## Problem

After waking from sleep, the PC would immediately go back to sleep. This cycle repeated 3-4 times before the system would finally stay awake.

## Root Cause

The ZSA Moonlander keyboard has a "System Control" USB interface that can send power key events. When the system resumes from sleep:

1. USB devices reinitialize
2. The Moonlander's System Control interface re-registers with the kernel
3. This triggers a spurious power button event
4. GNOME's power button action is set to `suspend` (default)
5. System immediately suspends again

### Evidence from logs

```
journalctl -b 0 | grep -i "Power Button\|power key\|System Control"
```

Shows:
- `systemd-logind: Watching system buttons on /dev/input/event1 (ZSA Technology Labs Moonlander Mark I System Control)` - appears after each resume
- `systemd-logind: Power key pressed short.` - spurious event

Timeline from journal:
- `21:50:34` - System wakes from suspend
- `21:50:50` - "The system will suspend now!" (only 16 seconds later)

## Failed Workaround

Previously attempted fix in `nixos/common.nix`:

```nix
powerManagement.resumeCommands = ''
  ${pkgs.systemd}/bin/systemd-inhibit --what=sleep --who="post-resume-inhibit" \
    --why="Preventing immediate re-suspend after wake" --mode=block sleep 60 &
'';
```

This didn't work because `systemd-inhibit` only blocks idle/automatic sleep. Direct power button presses bypass inhibitors.

## Solution

Created `nixos/hardware/moonlander.nix` with a udev rule to ignore power key events from the Moonlander's System Control interface:

```nix
services.udev.extraRules = ''
  # ZSA Moonlander - allow hidraw access for configuration tools
  KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3297", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"

  # Disable power key from Moonlander System Control to prevent re-suspend on wake
  SUBSYSTEM=="input", ATTRS{idVendor}=="3297", ATTRS{name}=="*System Control*", ENV{LIBINPUT_IGNORE_DEVICE}="1", ENV{ID_INPUT_KEY}="0"
'';
```

Added to `hosts/personal-pc.nix`:
```nix
imports = [
  ...
  ../nixos/hardware/moonlander.nix
  ...
];
```

## Alternative Fixes

If the udev rule doesn't work, alternatives include:

1. **Change GNOME power button action**:
   ```bash
   gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
   ```

2. **Disable via logind** (add to NixOS config):
   ```nix
   services.logind.extraConfig = ''
     HandlePowerKey=ignore
   '';
   ```

## Useful Debugging Commands

```bash
# Check recent sleep/wake events
journalctl -b 0 | grep -iE "sleep|suspend|wake|PM:"

# Check what triggered suspend
journalctl -b 0 --since "TIME" --until "TIME+1min" | grep logind

# Check ACPI wake sources
cat /proc/acpi/wakeup

# Check current power button action
gsettings get org.gnome.settings-daemon.plugins.power power-button-action

# Monitor power button events in real-time
journalctl -f | grep -i "power key"
```

## References

- ZSA Moonlander vendor ID: `3297`
- Device name pattern: `ZSA Technology Labs Moonlander Mark I System Control`
- Issue date: 2024-12-13
