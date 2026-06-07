{ ... }:
{
  # libvirt/QEMU + virt-manager. Included only on hosts that want it (endgame);
  # the user's `libvirtd` group membership self-resolves via the group-exists
  # filter in the user module, so it's a no-op on hosts without this aspect.
  den.aspects.virtualisation.nixos =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu.swtpm.enable = true; # software TPM for guests
      };

      services.spice-autorandr.enable = true;
      services.spice-vdagentd.enable = true;

      programs.virt-manager = {
        enable = true;
        package = pkgs.virt-manager;
      };
    };

  # Persist VM definitions, storage pools and qemu state.
  den.aspects.virtualisation.persist.directories = [
    "/var/cache/libvirt"
    "/var/lib/libvirt"
    "/var/lib/qemu"
  ];
}
