{ den, megadots, ... }:
{
  den.aspects.endgame = {
    includes = [
      den.aspects.roles.base
      den.aspects.roles.workstation
      den.aspects.roles.gaming
      den.aspects.roles.dev
      megadots.core.boot.lanzaboote
      megadots.desktop.gnome
      megadots.core.linux-kernel
    ];

    # nixos-generate-config output for this machine. Imported straight in
    # rather than wrapped in an aspect under megadots/hardware/, because it
    # isn't reusable, it belongs to this host and it sits next to this file.
    # The '_' prefix keeps import-tree from picking it up as its own module.
    nixos.imports = [ ./_hardware.nix ];
  };
}
