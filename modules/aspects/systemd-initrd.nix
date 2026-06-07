{ ... }:
{
  den.aspects.systemd-initrd.nixos =
    { ... }:
    {
      # Use the systemd-based initrd. Required for the impermanence/tmpfs-root
      # setup and for lanzaboote (secure boot).
      boot.initrd.systemd.enable = true;

      # Start the vconsole setup only after local-fs.target, else it can have
      # trouble accessing its data on disk on a tmpfs root.
      systemd.services.systemd-vconsole-setup.after = [ "local-fs.target" ];
    };
}
