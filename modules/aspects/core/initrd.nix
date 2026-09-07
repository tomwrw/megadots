_: {
  # A systemd-based initrd.
  den.aspects.initrd.nixos =
    { config, ... }:
    {
      # systemd in the initrd. core/impermanence.nix's initrd bind mounts and
      # core/ephemeral-btrfs.nix's rollback service both need it: the rollback
      # is an initrd systemd unit, and without systemd there is nothing to run
      # it or to order it before sysroot.mount.
      boot.initrd.systemd.enable = true;

      # The line above is the only reason this aspect isn't one setting, and
      # turning it off fails at the worst moment - the rollback never runs, so
      # the root subvolume silently stops being ephemeral and /persist stops
      # being the only state, or the machine does not boot at all.
      #
      # Asserted here rather than in flake/checks.nix, which deliberately holds
      # no invariants, and so that the guard travels with the aspect. Same shape
      # as hardware/surface-pro.nix. This aspect sets the option itself, so what
      # it really catches is something else overriding it at a higher priority.
      assertions = [
        {
          assertion = config.boot.initrd.systemd.enable;
          message = "core.initrd: boot.initrd.systemd.enable is false - the btrfs rollback in core/ephemeral-btrfs.nix is an initrd systemd unit and will not run, so the root subvolume stops being ephemeral. Something is defining it at a higher priority (mkForce?).";
        }
      ];

      # Start the vconsole setup only after local-fs.target, else it might have
      # trouble accessing data on disk.
      systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
    };
}
