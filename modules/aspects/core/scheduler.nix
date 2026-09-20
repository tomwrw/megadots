_: {
  # A sched_ext scheduler and an auto-nice daemon: the two halves CachyOS
  # installs by default on top of its kernel, and the part of "CachyOS feel"
  # that core/linux-kernel.nix alone does not deliver. The lto variants are
  # EEVDF, not BORE - nyx and upstream both only apply the BORE patch to the
  # bore/hardened/rt-bore flavours, and once a sched_ext scheduler is loaded
  # the in-kernel class is bypassed anyway, so this is where the scheduler
  # choice actually happens.
  #
  # Nothing here changes an idle desktop. It is for the moment a game or a
  # rebuild pegs every thread and the compositor, audio and input still have
  # to get CPU on time.
  #
  # Opt-in per host rather than in a role: bpfland is tuned for interactive
  # load on a many-core desktop, and I want it proven on endgame before the
  # Surface takes it. It works on the stock kernel too (sched_ext is in
  # nixpkgs' config from 6.12), so that is one include away.
  #
  # Safe to try: the kernel keeps EEVDF resident and reverts every task to it
  # the moment the BPF scheduler exits, crashes or trips the starvation
  # watchdog. 'systemctl stop scx' is the A/B switch, no reboot needed.
  den.aspects.scheduler.nixos =
    { pkgs, ... }:
    {
      services.scx = {
        enable = true;
        # rustscheds, not the default scx.full: bpfland and lavd are both Rust
        # schedulers, so full only adds the C ones I will not run.
        package = pkgs.scx.rustscheds;
        # CachyOS' documented default. Splits tasks into interactive and
        # regular by voluntary context-switch rate and queues the interactive
        # ones first, which is exactly "desktop stays responsive while
        # compiling". scx_lavd is the swap if this ever stalls - it is what
        # Valve ships on the Deck. Default flags first; '-P' (fill the
        # higher-ranked cores first) is the one worth trying after.
        scheduler = "scx_bpfland";
      };

      # ananicy-cpp with CachyOS' rules: per-executable nice, ionice and
      # oom_score_adj, so a compiler or a torrent client is demoted the moment
      # it starts and a game is promoted. It composes with scx - a nice value
      # is a weight bpfland reads too. If the desktop ever stalls, this is
      # the first thing to switch off, before blaming the scheduler.
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
      };
    };
}
