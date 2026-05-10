# Known Issues

## RX 7900 XTX silent kernel hang on Chrome tab close / DXVK workloads

- **Affected hardware:** Sapphire/reference RX 7900 XTX (Navi 31, gfx1100, PCI ID `1002:744C`) on `nyancat`. Reproduced on kernels 7.0.1 and 7.0.2.
- **Symptom:** Total system lockup with no journal output. Kernel printk buffer just stops mid-stream — no `device lost from bus`, no fence timeout, no AER, no DRM scheduler error. Case fans ramp to 100% (BIOS Q-Fan failsafe — OS stopped updating PWM). Hard reset is the only recovery. `pstore` captured nothing because `kernel.panic=0` means the kernel hangs forever after panic instead of writing.
- **Trigger:** Reproducibly when closing the **Unifi admin panel tab in Chrome** (heavy WebGL / canvas dashboard, releases a large pile of GPU resources at once). Also observed mid-session under DXVK workloads (Overwatch via Wine). Common pattern: many GPU buffer frees under contention.
- **Root cause:** Navi 31 has a known kernel-level TLB / DMA-fence bug in the scatter-gather display buffer free path. Freeing SG-mapped display buffers while the MES is busy can leave the GPU's MMU in a state where the TLB-invalidate fence never completes; the amdgpu driver waits inside a non-printk-able path, the rest of the kernel stalls behind it, fans default to BIOS failsafe.
- **Workaround:** `amdgpu.sg_display=0` on the kernel cmdline (set in `personalPc` block in `flake.nix`). Forces display buffers through the contiguous CMA path instead of SG/IOMMU. Small VRAM-bandwidth cost, big stability win. Combined with `kernel.panic=10` / `kernel.panic_on_oops=1` / `kernel.hung_task_panic=1` so any future hang gets captured by `efi_pstore` (read on next boot via `sudo cat /sys/fs/pstore/dmesg-*`).
- **Status:** Mitigated 2026-05-03 — monitoring. The pre-existing `pcie_aspm.policy=performance` workaround was for a different signature (`device lost from bus` with logged SMU errors); both stay in place.

## RX 7900 XTX MES wedge during DRM file close from Chromium-based apps

- **Affected hardware:** RX 7900 XTX on `nyancat`. Reproduced on kernel 7.0.3 with VCN/JPEG already disabled via `amdgpu.ip_block_mask=0xfffffcff`.
- **Symptom:** Logged `device lost from bus` with a clear preamble (unlike the silent-hang above). Display freezes, fans go to 100%. Importantly, the system slowly *rots into unreachability*: TTM kthreads pile up on `dma_fence_wait` for fences belonging to GPU work the dead card will never complete (`Workqueue: ttm ttm_bo_delayed_delete`); after enough wedged workers the kernel workqueue saturates and SSH stops responding. Without `kernel.hung_task_panic=1`, only a hard reset recovers.
- **Trigger:** A Chromium-based app's GPU resources being released while a long-running compute workload is hammering the GPU. Observed 2026-05-09: model training (`uv run train.py`) running in the background, then `1password` (Electron/CEF) was closed — its DRM file release path triggered VM cleanup that the MES couldn't service. Earlier 2026-05-07 hit had Chrome as the trigger; same shape.
- **Root cause:** The MES (Micro Engine Scheduler) firmware on Navi 31 wedges under cleanup contention. dmesg signature, in order:
  ```
  amdgpu: MES failed to respond to msg=MISC (WAIT_REG_MEM)
  amdgpu: failed to reg_write_reg_wait
  amdgpu: MES ring buffer is full        ← repeats for ~15s
  amdgpu: VM memory stats for proc <chromium-app>(pid) task ...:cs0(pid) is non-zero when fini
  amdgpu: reset sdma queue (0:0:0)
  amdgpu: failed to wait on sdma queue reset done
  amdgpu: Ring sdma0 reset failed
  amdgpu: GPU reset begin!. Source:  1
  amdgpu: device lost from bus!
  amdgpu: GPU reset end with ret = -19
  ```
  The MES is mandatory on `gfx_v11` — there is no legacy KIQ fallback to switch to. `amdgpu.mes=0` is not a usable workaround.
- **Workaround options:**
  1. **Recovery, not prevention:** `kernel.hung_task_panic=1` ensures the system auto-reboots within ~120s (`hung_task_timeout_secs`) of the first wedged task instead of slowly suffocating into SSH-unreachability. pstore captures the trace. Set in `personalPc` sysctl block.
  2. **Avoidance:** disable hardware acceleration in Chromium-based apps (1Password, Spotify, Chrome extensions that do GPU work) so they never allocate GPU resources. Per-app config; not robust.
  3. **Upstream fix needed:** check linux-firmware updates for newer Navi 31 MES firmware; track amdgpu mailing list for `MES failed to respond` reports on `gfx_v11`.
- **Status:** Recovery mitigation in place 2026-05-09 (`kernel.hung_task_panic=1`). Root cause unfixed; capture pstore on next occurrence to see if signature changes after the gfxoff disable (`amdgpu.ppfeaturemask=0xfff7bdff`, applied same day).

## MediaTek MT7927 Wi-Fi 7 chip has no mainline driver

- **Affected hardware:** ASUS ProArt X870E-CREATOR WIFI on-board WiFi — MediaTek MT7927 (Filogic 380, PCI `14c3:7927`, paired with MT6639 Bluetooth). Confirmed on kernel 7.0.2.
- **Symptom:** No `wlan*` interface ever appears. `lspci -nnk` shows the device at `0c:00.0 Network controller [0280]: MEDIATEK Corp. Device [14c3:7927]` with no "Kernel driver in use" line. `dmesg` is silent — nothing tries to bind. Bluetooth side (`hci0`) does come up via the shared MT6639.
- **Root cause:** MT7927 is not yet supported by any mainline kernel driver. Architecturally close to MT7925, so upstream is extending `mt7925e` rather than adding a separate `mt7927e` module — but kernel 7.0.2's `mt7925e` only declares PCI aliases `14c3:0717` and `14c3:7925`. Forcing the binding with `new_id` does not work; the chip needs a different DMA/firmware-load path. A v2 patch series "wifi: mt76: mt7925: add MT7927 (Filogic 380) support" is in review on linux-wireless but unmerged. Firmware path is `mediatek/mt7925/` (already in `linux-firmware`) plus an additional MT6639/MT7927 blob whose final filename in `linux-firmware` is not finalized — the out-of-tree DKMS package fetches it from the ASUS CDN today.
- **Workaround options:**
  1. **Recommended:** swap the M.2 2230 module for an **Intel AX210 / BE200** — full mainline `iwlwifi` support, no config needed.
  2. Package [`jetm/mediatek-mt7927-dkms`](https://github.com/jetm/mediatek-mt7927-dkms) as a `boot.extraModulePackages` derivation and add the ASUS firmware via `hardware.firmware`. Requires kernel ≥6.17 (satisfied at 7.0.2). Will need re-patching on each kernel bump until upstream lands.
  3. Wait for the v2 series to merge — once it's in a stable kernel, `mt7925e` should pick the chip up automatically.
- **Status:** Unfixed as of 2026-05-03. The Wired NIC (`enp13s0`, Intel I226-V `igc`) is the only network path on this box. Bluetooth via MT6639 still works.
- **References:**
  - DKMS: https://github.com/jetm/mediatek-mt7927-dkms
  - Patch series: https://lwn.net/Articles/1063834/
  - Writeup: https://jetm.github.io/blog/posts/mt7927-wifi-making-it-work/
  - mt76 tracking issue: https://github.com/openwrt/mt76/issues/927

## `atlantic` driver deadlock on suspend wedges the system

- **Affected hardware:** ASUS ProArt X870E-CREATOR WIFI — Marvell/Aquantia AQC113 10GbE NIC (`enp14s0`, `atlantic` driver). Reproduced on kernel 7.0.1.
- **Symptom:** After a suspend attempt, new processes hang at startup, networking calls block forever, and `systemctl reboot` cannot complete (services time out, `Still around after SIGKILL`). Only a hard reset recovers.
- **Trigger:** System enters suspend while the 10GbE port has no carrier. NetworkManager calls `aq_ndev_close` to bring the link down; the driver hangs in `napi_disable_locked` waiting for NAPI to quiesce.
- **Root cause:** NetworkManager is stuck holding `rtnl_mutex` inside the atlantic suspend path. Every subsequent rtnetlink call (basically any process that initializes networking) blocks in uninterruptible (D) state on the same mutex. `SIGKILL` is ignored on D-state tasks, so shutdown can't proceed either.
- **Workaround:** Blacklist the `atlantic` module. The 10GbE port is not in use on this machine — the active NIC is the Intel I225/I226 (`enp13s0`, `igc`). See `boot.blacklistedKernelModules` in the `personalPc` block in `flake.nix`.
- **Status:** Worked around. Revisit if the 10GbE port is ever needed; check upstream kernel changelog for fixes to `aq_nic_stop` / `napi_disable_locked` on suspend.

## EPOS GSX 300 PCM wedges after USB reset

- **Affected hardware:** Sennheiser EPOS GSX 300 (USB `1395:0098`), connected through a USB switch + powered USB hub on `nyancat`. Direct USB connection is not an option in this setup. Reproduced on kernel 7.0.2 with PipeWire 1.4.9.
- **Symptom:** Audio output to the headset stops mid-session. PipeWire still shows the device, but playback is silent. The USB device remains enumerated in `/sys/bus/usb/devices` (and the hardware volume knob keeps reporting position changes), so it looks healthy from userspace, but the ALSA PCM is dead. Sometimes preceded by audio glitches and spurious GSX 300 "Smart Button" events (the `epos-smart-button` user service flips the default sink as if the button were pressed).
- **Trigger:** xHCI-level USB reset on the GSX 300 — visible in `dmesg` as `usb X-Y.Z.W: reset full-speed USB device number N using xhci_hcd`. Most likely caused by signal-integrity or power issues on the USB switch + hub chain (long cable runs, marginal hub power, switch chip glitches).
- **Root cause:** When the USB device resets, snd-usb-audio's PCM endpoints become invalid mid-stream. PipeWire's existing PCM handles return `ENODEV` from every operation:
  ```
  spa.alsa: hw:0c: snd_pcm_status error: No such device
  spa.alsa: hw:0c: snd_pcm_prepare error: No such device
  spa.alsa: hw:0c: close failed: No such device
  ```
  PipeWire does not re-open the device automatically, and even restarting `wireplumber pipewire pipewire-pulse` does not recover — the kernel-side PCM is stuck. Only a full USB re-enumeration of the device (physical replug or sysfs unbind/bind) restores audio.
- **Workaround:** `epos-self-heal` system service tails the system journal for the `spa.alsa.*No such device` pattern; when seen, it locates the EPOS USB device by vendor/product ID (path-independent — works through the hub/switch on whatever bus position the device shows up on) and rebinds it via `/sys/bus/usb/drivers/usb/{un,bind}` after a short debounce. 60s cooldown prevents flapping. Defined in `nixos/hardware/epos.nix`.
- **Status:** Mitigated 2026-05-07. The underlying USB instability is unfixed; if it gets worse, replace the USB switch/hub or move the GSX 300 to a direct port.

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
