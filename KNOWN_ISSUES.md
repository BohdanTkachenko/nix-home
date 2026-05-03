# Known Issues

## RX 7900 XTX silent kernel hang on Chrome tab close / DXVK workloads

- **Affected hardware:** Sapphire/reference RX 7900 XTX (Navi 31, gfx1100, PCI ID `1002:744C`) on `nyancat`. Reproduced on kernels 7.0.1 and 7.0.2.
- **Symptom:** Total system lockup with no journal output. Kernel printk buffer just stops mid-stream — no `device lost from bus`, no fence timeout, no AER, no DRM scheduler error. Case fans ramp to 100% (BIOS Q-Fan failsafe — OS stopped updating PWM). Hard reset is the only recovery. `pstore` captured nothing because `kernel.panic=0` means the kernel hangs forever after panic instead of writing.
- **Trigger:** Reproducibly when closing the **Unifi admin panel tab in Chrome** (heavy WebGL / canvas dashboard, releases a large pile of GPU resources at once). Also observed mid-session under DXVK workloads (Overwatch via Wine). Common pattern: many GPU buffer frees under contention.
- **Root cause:** Navi 31 has a known kernel-level TLB / DMA-fence bug in the scatter-gather display buffer free path. Freeing SG-mapped display buffers while the MES is busy can leave the GPU's MMU in a state where the TLB-invalidate fence never completes; the amdgpu driver waits inside a non-printk-able path, the rest of the kernel stalls behind it, fans default to BIOS failsafe.
- **Workaround:** `amdgpu.sg_display=0` on the kernel cmdline (set in `personalPc` block in `flake.nix`). Forces display buffers through the contiguous CMA path instead of SG/IOMMU. Small VRAM-bandwidth cost, big stability win. Combined with `kernel.panic=10` / `kernel.panic_on_oops=1` so any future hang gets captured by `efi_pstore` (read on next boot via `sudo cat /sys/fs/pstore/dmesg-*`).
- **Status:** Mitigated 2026-05-03 — monitoring. The pre-existing `pcie_aspm.policy=performance` workaround was for a different signature (`device lost from bus` with logged SMU errors); both stay in place.

## `atlantic` driver deadlock on suspend wedges the system

- **Affected hardware:** ASUS ProArt X870E-CREATOR WIFI — Marvell/Aquantia AQC113 10GbE NIC (`enp14s0`, `atlantic` driver). Reproduced on kernel 7.0.1.
- **Symptom:** After a suspend attempt, new processes hang at startup, networking calls block forever, and `systemctl reboot` cannot complete (services time out, `Still around after SIGKILL`). Only a hard reset recovers.
- **Trigger:** System enters suspend while the 10GbE port has no carrier. NetworkManager calls `aq_ndev_close` to bring the link down; the driver hangs in `napi_disable_locked` waiting for NAPI to quiesce.
- **Root cause:** NetworkManager is stuck holding `rtnl_mutex` inside the atlantic suspend path. Every subsequent rtnetlink call (basically any process that initializes networking) blocks in uninterruptible (D) state on the same mutex. `SIGKILL` is ignored on D-state tasks, so shutdown can't proceed either.
- **Workaround:** Blacklist the `atlantic` module. The 10GbE port is not in use on this machine — the active NIC is the Intel I225/I226 (`enp13s0`, `igc`). See `boot.blacklistedKernelModules` in the `personalPc` block in `flake.nix`.
- **Status:** Worked around. Revisit if the 10GbE port is ever needed; check upstream kernel changelog for fixes to `aq_nic_stop` / `napi_disable_locked` on suspend.

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
