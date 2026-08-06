_: {
  den.aspects.virtualisation.libvirt.nixos = _: {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    # No spice-vdagentd or spice-autorandr. Those are SPICE guest agents, they
    # belong inside a VM so the client can drive its clipboard and resolution.
    # On the host they just sit in graphical.target doing nothing. The client
    # side is virt-manager, below.
    #
    # No package set, pkgs.virt-manager is already the module default.
    programs.virt-manager.enable = true;
  };

  den.aspects.virtualisation.libvirt.persist.directories = [
    "/var/cache/libvirt"
    "/var/lib/libvirt"
    # The local CA that issues vTPM endorsement certificates. Per-VM swtpm
    # state sits under /var/lib/libvirt but this CA doesn't, and without it
    # every vTPM gets a fresh EK certificate each boot.
    "/var/lib/swtpm-localca"
    # Not /var/lib/qemu. The libvirtd module refills it with tmpfiles symlinks
    # into the store every boot, so persisting it just collects dangling links
    # as the store gets collected.
  ];

  # The aspect that makes the libvirtd group is the one that grants it. Only
  # hosts including this aspect deliver it, so the user side needs no guard.
  den.aspects.virtualisation.libvirt.provides.to-users =
    { host, user, ... }:
    {
      name = "virtualisation.libvirt/libvirtd-group(${user.userName}@${host.name})";
      nixos.users.users.${user.userName}.extraGroups = [ "libvirtd" ];
    };
}
