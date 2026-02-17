# Known Issues

## GNOME login screen defaults to Ukrainian input language

The GDM login screen may have the input language set to Ukrainian instead of
English. This causes password entry to fail silently since keystrokes produce
unexpected characters.

**Workaround:** Switch the input language back to English using the keyboard
layout indicator in the top bar before typing the password.

**Potential fix:** The [Primary Input on LockScreen](https://extensions.gnome.org/extension/4727/primary-input-on-lockscreen/)
GNOME extension automatically switches the keyboard layout to the primary one
(first in your list) whenever the lock screen activates. Supports GNOME Shell
45–49.

**Ideal fix:** Configure GDM to default to English and remove the option to
switch input languages on the login screen.

**References:**
- https://discourse.gnome.org/t/how-do-i-set-english-only-in-gdm/26853/3
- https://discourse.gnome.org/t/lock-screen-input-language-intended-behavior/4167/10
- https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/225
- https://discussion.fedoraproject.org/t/change-default-language-to-login-fedora/76715/3

## PC immediately goes back to sleep after waking from suspend

After waking from suspend, the system re-suspends within 15-25 seconds,
creating a loop that makes it nearly impossible to unlock the screen. The user
may see the lock screen briefly but the system suspends again before they can
enter their password.

**Root cause:** USB keyboards (ZSA Moonlander, Keychron Ultra-Link 8K) have the
`power-switch` udev tag, which causes systemd-logind to watch them for
sleep/power button events. During USB re-enumeration after resume, these
keyboards send spurious sleep key events that trigger an immediate re-suspend.

The original udev workaround in `moonlander.nix` was ineffective because:
1. It used `ATTRS{name}` (parent traversal) combined with `ATTRS{idVendor}` at
   a different device hierarchy level, so the rule never matched.
2. It set `LIBINPUT_IGNORE_DEVICE` and `ID_INPUT_KEY` which only affect
   libinput, not systemd-logind. Logind uses the `power-switch` udev tag to
   decide which devices to monitor.

**Fix:** Remove the `power-switch` tag from keyboard input devices using
`TAG-="power-switch"` with `ATTR{name}` (current device level, no parent
traversal) in udev rules. See `moonlander.nix` and `keychron.nix`.

**Diagnosis commands:**
```sh
# Check which devices have the power-switch tag
udevadm info /dev/input/eventN | grep power-switch

# Check what logind is watching for button events
journalctl -b 0 -u systemd-logind | grep "Watching system buttons"

# Check for rapid suspend/wake cycles
journalctl -b 0 -u systemd-logind | grep -E "suspend now|suspend.*finished"
```
