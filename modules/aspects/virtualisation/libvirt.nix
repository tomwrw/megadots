_: {
  den.aspects.virtualisation.libvirt.nixos =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;
      };

      services.spice-autorandr.enable = true;
      services.spice-vdagentd.enable = true;

      programs.virt-manager = {
        enable = true;
        package = pkgs.virt-manager;
      };
    };

  den.aspects.virtualisation.libvirt.persist.directories = [
    "/var/cache/libvirt"
    "/var/lib/libvirt"
    "/var/lib/qemu"
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
