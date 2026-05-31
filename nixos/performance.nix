# System performance optimizations inspired by CachyOS
{
  config,
  lib,
  pkgs,
  ...
}:
{

  # GameMode: per-game performance boost activated via gamemoderun or Steam's
  # built-in integration. Switches CPU governor to "performance", raises I/O
  # priority, disables screensaver, and applies GPU clock optimizations.
  # Complements ananicy (which handles background deprioritization) by actively
  # boosting the foreground game. Gaming-only.
  programs.gamemode.enable = config.my.gaming.enable;

  # power-profiles-daemon: runtime power/perf knob exposed via GNOME's power
  # menu and `powerprofilesctl`. On amd-pstate-epp it maps performance/balanced/
  # power-saver to EPP performance/balance_performance/power. Doesn't conflict
  # with scx_lavd — different layer (EPP vs scheduler). Tied to the graphical
  # session since its only UI lives in GNOME.
  services.power-profiles-daemon.enable = config.my.gui.enable;

  # CCD pinning wrappers for the 9950X3D's asymmetric topology:
  #   CCD0 (cores 0-7, threads 0-7,16-23): V-cache, 96MB L3 — best for games
  #   CCD1 (cores 8-15, threads 8-15,24-31): standard, 32MB L3, slightly higher
  #     boost — best for parallel compute (cargo/rustc/cc/nix-build)
  #
  # ananicy-cpp deprioritizes builds but the scheduler still lets them steal
  # time on idle V-cache cores. taskset enforces hard physical isolation.
  #
  # Usage:
  #   Steam launch options: gamemoderun game-run %command%
  #   Background builds:    build-run cargo build  /  build-run nix build
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "game-run" ''
      exec ${pkgs.util-linux}/bin/taskset -c 0-7,16-23 "$@"
    '')
    (pkgs.writeShellScriptBin "build-run" ''
      exec ${pkgs.util-linux}/bin/taskset -c 8-15,24-31 "$@"
    '')
  ];

  # ananicy-cpp: auto-nice daemon that assigns CPU/IO priorities by process name.
  # Deprioritizes known heavy background processes (cargo, rustc, cc, ld, etc.)
  # and boosts interactive/game processes — system-wide, regardless of how they're
  # launched (shell, direnv, IDE, etc.). CachyOS rules provide the most
  # comprehensive ruleset, especially for gaming and development tools.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # sched-ext: BPF-based userspace CPU scheduler (requires kernel >= 6.12).
  # scx_lavd uses "Latency and Virtual Deadline" scheduling — optimized for
  # interactive/gaming workloads by prioritizing latency-sensitive tasks.
  #
  # Disabled 2026-04-30: on this 9950X3D + heavy multi-app desktop workload
  # (OW2 + Spotify + Chrome + comfyui + AI tooling), scx_lavd over-pinned
  # everything to a single V-cache core (primary CPU [7], 3.16% capacity
  # bound) and caused system-wide micro-stutters — Spotify hangs, OW2 frame
  # drops. EEVDF + ananicy-cpp + amd_x3d_mode=cache + explicit CCD pinning
  # via game-run/build-run wrappers gives smoother results without the
  # scheduler bias. Re-enable to test if scx_lavd improves on a specific
  # workload, but expect to retune everything else around it.
  services.scx = {
    enable = false;
    scheduler = "scx_lavd";
  };

  # zram: compressed RAM-backed swap. Much faster than disk swap because
  # decompressing from RAM is orders of magnitude faster than reading from
  # even an NVMe SSD. With zstd compression, ~2-3x effective memory before
  # hitting the disk swapfile (which is still there for hibernation).
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # Use up to half of RAM for compressed swap. With ~3x compression ratio
    # this effectively extends usable memory by ~1.5x before hitting disk.
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    # With zram, swappiness should be high — zram swap is fast (just
    # decompression in RAM), so the kernel should prefer swapping idle pages
    # to zram over evicting filesystem caches. CachyOS default: 100.
    "vm.swappiness" = 100;

    # Keep filesystem dentries and inodes in cache longer. Default is 100
    # (reclaim caches at the same rate as pagecache). Lower values make the
    # kernel prefer to keep VFS caches, which improves file access latency —
    # noticeable in large builds and game asset loading.
    "vm.vfs_cache_pressure" = 50;

    # Read single pages from swap instead of clusters of 8. The default
    # (3 = 2^3 = 8 pages) assumes slow disk swap where sequential reads help.
    # With zram, each page decompresses independently, so clustering just
    # wastes memory bandwidth.
    "vm.page-cluster" = 0;

    # Disable proactive memory compaction. The kernel normally compacts memory
    # in the background to create large contiguous blocks. This burns CPU
    # cycles for a benefit that's mostly relevant to VMs with huge pages.
    # For a desktop/gaming system, the overhead isn't worth it.
    "vm.compaction_proactiveness" = 0;

    # Disable the kernel's automatic scheduling group heuristic. When enabled,
    # the kernel creates a separate scheduling group per TTY session, which
    # can interfere with ananicy-cpp's explicit priority assignments. Since
    # we're using ananicy-cpp to manage process priorities, autogroups would
    # just fight with it.
    "kernel.sched_autogroup_enabled" = 0;

    # Disable split-lock mitigation. The default (`1` = warn + 10ms sleep
    # penalty per offending task per trap) was designed for Intel, where bus
    # locks across cache lines can be abused as a noisy-neighbor side channel
    # in cloud/multi-tenant scenarios. AMD doesn't have that concern, and on
    # this single-user desktop the security benefit is zero — the cost is
    # real: Steam alone trips ~100k+ traps in the first minute after launch
    # (`x86/split lock detection: #DB: steam/...`), each one paying the sleep
    # penalty. Wine/Proton workloads are notorious for split-locks. Setting
    # this to `0` removes both the warning spam and the per-trap sleep, with
    # no downside on AMD.
    "kernel.split_lock_mitigate" = 0;
  };

  # NVMe drives have their own sophisticated internal queue management with
  # multiple hardware queues. Adding a software I/O scheduler on top just
  # adds latency. "none" passes requests straight through to the device.
  #
  # AMD 3D V-Cache Performance Optimizer (X3D CPUs only): set mode to "cache"
  # so the kernel prefers the V-cache CCD (CCD0, 96MB L3) for latency-sensitive
  # single-thread loads instead of the higher-boost CCD1. Games benefit far
  # more from L3 hits than from the extra ~200 MHz on CCD1. The driver only
  # binds on X3D parts (AMDI0101), so this rule is a no-op on other hardware.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="platform", DRIVER=="amd_x3d_vcache", ATTR{amd_x3d_mode}="cache"
  '';
}
