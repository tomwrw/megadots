_: {
  den.aspects.virtualisation.libvirt.nixos = _: {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    # No spice-vdagentd / spice-autorandr here: those are SPICE *guest* agents,
    # meant to run inside a VM so the SPICE client can drive its clipboard and
    # resolution. On the host they sit in graphical.target doing nothing. The
    # client side is virt-viewer/virt-manager, below.
    #
    # package is not set: pkgs.virt-manager is already the module default.
    programs.virt-manager.enable = true;
  };

  den.aspects.virtualisation.libvirt.persist.directories = [
    "/var/cache/libvirt"
    "/var/lib/libvirt"
    # The local CA that issues vTPM endorsement certificates. Per-VM swtpm
    # state lives under /var/lib/libvirt, but this CA does not - without it
    # every vTPM gets a fresh EK certificate on each boot.
    "/var/lib/swtpm-localca"
    # Deliberately NOT /var/lib/qemu: nixpkgs' libvirtd module repopulates it
    # with 'L+' tmpfiles symlinks into the store on every boot, so persisting
    # it only accumulates dangling links as the store garbage-collects.
  ];

  # The aspect that creates the libvirtd group grants it. Only hosts
  # including `virtualisation.libvirt` deliver this, so no host-existence
  # guard is needed at the user site.
  den.aspects.virtualisation.libvirt.provides.to-users =
    { host, user, ... }:
    {
      name = "virtualisation.libvirt/libvirtd-group(${user.userName}@${host.name})";
      nixos.users.users.${user.userName}.extraGroups = [ "libvirtd" ];
    };
}
