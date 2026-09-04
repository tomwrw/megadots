_: {
  # A systemd-based initrd.
  den.aspects.initrd.nixos = _: {
    # systemd in the initrd. impermanence's initrd bind mounts and the btrfs
    # rollback both need it, and checks.nix asserts it stays on.
    boot.initrd.systemd.enable = true;

    # Start the vconsole setup only after local-fs.target, else it might have
    # trouble accessing data on disk.
    systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
  };
}
