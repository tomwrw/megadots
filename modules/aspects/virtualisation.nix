_: {
  den.aspects.virtualisation.nixos =
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

  den.aspects.virtualisation.persist.directories = [
    "/var/cache/libvirt"
    "/var/lib/libvirt"
    "/var/lib/qemu"
  ];
}
