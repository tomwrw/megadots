{ den, ... }:
{
  den.aspects.endgame = {
    includes = [
      den.aspects.roles.base
      den.aspects.roles.workstation
      den.aspects.roles.gaming
      den.aspects.roles.dev
      den.aspects.core.boot.lanzaboote
      den.aspects.virtualisation.libvirt
      den.aspects.core.linux-kernel
    ];

    # nixos-generate-config output for this machine. Imported directly rather
    # than through a wrapper aspect in aspects/hardware/: it is not reusable,
    # it belongs to this host, and it sits right next to this file. The '_'
    # prefix is what keeps import-tree from picking it up as a module of its own.
    nixos.imports = [ ./_hardware.nix ];
  };
}
