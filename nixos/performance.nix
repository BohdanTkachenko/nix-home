# System performance optimizations inspired by CachyOS
{ pkgs, ... }:
{

  # GameMode: per-game performance boost activated via gamemoderun or Steam's
  # built-in integration. Switches CPU governor to "performance", raises I/O
  # priority, disables screensaver, and applies GPU clock optimizations.
  # Complements ananicy (which handles background deprioritization) by actively
  # boosting the foreground game.
  programs.gamemode.enable = true;

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
  # This is CachyOS's flagship feature and the biggest single improvement
  # for desktop responsiveness under load.
  services.scx = {
    enable = true;
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
  };

  # NVMe drives have their own sophisticated internal queue management with
  # multiple hardware queues. Adding a software I/O scheduler on top just
  # adds latency. "none" passes requests straight through to the device.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';
}
