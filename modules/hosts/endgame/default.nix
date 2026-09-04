{ den, ... }:
{
  den.aspects.endgame = {
    includes = [
      # Roles
      den.aspects.base
      den.aspects.workstation
      den.aspects.gaming
      den.aspects.dev

      # The choices only this machine makes
      den.aspects.boot.lanzaboote
      den.aspects.gnome
      den.aspects.linux-kernel
    ];

    # nixos-generate-config output for this machine. Imported straight in rather
    # than wrapped in an aspect: it is not reusable, it belongs to this host, and
    # it sits next to this file. The '_' prefix keeps import-tree from picking it
    # up as a module of its own.
    nixos.imports = [ ./_hardware.nix ];
  };
}
