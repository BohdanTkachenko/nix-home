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
