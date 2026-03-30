# Known Issues

## GNOME Shell crash: `shell_app_dispose` assertion failure

- **Upstream:** [GNOME/gnome-shell#7045](https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7045)
- **Affected version:** gnome-shell 49.2
- **Symptom:** gnome-shell aborts with `assertion failed: (app->state == SHELL_APP_STATE_STOPPED)` in `shell_app_dispose`, causing GDM to restart and drop to the login screen.
- **Trigger:** Desktop file changes (e.g. from `chromium-pwa-wmclass-sync`) cause an `installed_changed` signal, which disposes a `ShellApp` that is still in a running state.
- **Root cause:** Since commit `1807be12`, removing the last window of an app clears the fallback icon and emits a `notify` signal before syncing the app state to `STOPPED`. Handlers responding to the notify hit the assertion.
- **Workaround:** None known. Extensions like dash-to-dock and rounded-window-corners may contribute to triggering the bad state.
- **Status:** Fixed upstream; check if the fix is included in a newer gnome-shell package.
- **Logs:**
  - [Journal logs (2026-04-02)](docs/logs/2026-04-02-gnome-shell-crash.log)
  - [Stack trace (2026-04-02)](docs/logs/2026-04-02-gnome-shell-crash-stacktrace.log)
