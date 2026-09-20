_: {
  # The desktop-latency tuning CachyOS ships as cachyos-settings, minus what
  # the CachyOS kernel already defaults to (vm.swappiness=100, vm.page-cluster=0)
  # and minus anything that is a security trade - those stay in core/hardening.nix
  # where the trade is written down. Nothing here needs the CachyOS kernel;
  # the scheduler that does is core/scheduler.nix.
  den.aspects.performance.nixos = _: {
    boot.kernel.sysctl = {
      # Dirty-page limits in bytes, not ratios. The defaults are 20%/10% of
      # RAM, which on 30 GiB is 6 GiB of dirty pages before a writer is
      # throttled - so a big copy or a rebuild unpacking a closure fills the
      # page cache for seconds and then stalls everything on one enormous
      # writeback. 256 MiB / 64 MiB keeps the flusher continuously busy
      # instead, and a stall, if it comes, is a fraction of a second. Setting
      # the _bytes form zeroes the _ratio one, which is the intent.
      "vm.dirty_bytes" = 268435456;
      "vm.dirty_background_bytes" = 67108864;
      # Wake the flusher every 15 s rather than 5 s. With the byte limits
      # above doing the real work this only trims idle wakeups.
      "vm.dirty_writeback_centisecs" = 1500;

      # Keep dentries and inodes cached longer relative to page cache. 100 is
      # even-handed; 50 favours the metadata that makes a cold 'ls' or a
      # Firefox start feel slow once it has been reclaimed.
      "vm.vfs_cache_pressure" = 50;

      # The NMI watchdog fires a periodic interrupt on every core to detect
      # hard lockups. I have never had one; the interrupt costs power and
      # jitter. The hardware watchdog modules are blacklisted below for the
      # same reason.
      "kernel.nmi_watchdog" = 0;

      # Deeper per-CPU receive backlog so a burst on the LAN is queued rather
      # than dropped while the desktop is busy.
      "net.core.netdev_max_backlog" = 4096;
    };

    # Neither host uses a hardware watchdog, so the drivers only add a module
    # to load and a timer to service. sp5100_tco is the AMD one and is what
    # endgame was loading; iTCO_wdt is the Intel one.
    boot.blacklistedKernelModules = [
      "iTCO_wdt"
      "sp5100_tco"
    ];

    # I/O schedulers by device class, straight from cachyos-settings'
    # 60-ioschedulers.rules. Both hosts boot from NVMe, which nixpkgs leaves on
    # mq-deadline. kyber is built for it: a read latency target it throttles
    # writes to meet, so a background write flood cannot starve the page
    # faults the desktop is waiting on. Not adios - only the CachyOS kernel
    # has it, and this aspect is in base.
    #
    # The other two lines cost nothing on a host without such a disk and mean
    # an external SSD or HDD gets a sane scheduler the moment it is plugged in.
    # bfq is a module on the stock kernel; writing the name loads it.
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    '';

    # THP is 'always' on the CachyOS kernel and 'madvise' on stock; this only
    # matters for the former. 409 of 512 PTEs: a huge page that is more than
    # 80% zero-filled gets split by khugepaged instead of pinning 2 MiB for a
    # sparse allocation, which is most of the memory bloat 'always' gets
    # blamed for. w! not w, so it is written at boot and not re-applied on
    # every switch - it will not show up until the reboot after adding it.
    systemd.tmpfiles.rules = [
      "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
    ];

    # systemd-oomd is on by default in nixpkgs but watches nothing, so it has
    # never once fired. Fedora's split: the root slice, so a runaway build
    # under system.slice is caught, and the user slices, so a tab that eats
    # 30 GiB loses that one cgroup rather than the whole session sitting in
    # swap thrash until the kernel OOM killer gives up. Not system.slice as
    # well - the root slice already reaches into it, and per-slice monitoring
    # there would take out nix-daemon whole rather than one build.
    systemd.oomd = {
      enableRootSlice = true;
      enableUserSlices = true;
      # Fedora's 20 s rather than upstream's 30 s: 30 s of full memory
      # pressure is already the freeze this exists to prevent.
      settings.OOM.DefaultMemoryPressureDurationSec = "20s";
    };

    # /var/log is persisted (core/impermanence.nix) and journald was unbounded,
    # so each machine-id ever booted left its journal behind: 1.2 GiB across
    # ~60 directories before the machine-id fix. journald only vacuums its own
    # machine-id directory, so the cap keeps *this* one honest; the stale
    # siblings are a one-off 'rm' by hand, not something to automate against
    # /var/log.
    services.journald.settings.Journal.SystemMaxUse = "512M";
  };
}
