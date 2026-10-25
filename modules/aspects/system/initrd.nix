_: {
  # Initrd tweaks.
  #
  # This used to set boot.initrd.systemd.enable and assert it stayed set, because
  # system/impermanence.nix's initrd bind mounts and system/ephemeral-btrfs.nix's
  # rollback service are both initrd systemd units. nixpkgs has since removed the
  # scripted initrd and the option with it - a systemd initrd is the only kind -
  # so there is nothing left to set or guard.
  den.aspects.initrd.nixos = _: {
    # Start the vconsole setup only after local-fs.target, else it might have
    # trouble accessing data on disk.
    systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
  };
}
