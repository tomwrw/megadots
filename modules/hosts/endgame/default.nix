{ den, ... }:
{
  den.aspects.endgame = {
    includes = [
      den.aspects.roles.default
      den.aspects.roles.workstation
      den.aspects.roles.gaming
      den.aspects.core.boot.lanzaboote
      den.aspects.virtualisation.libvirt
      den.aspects.core.linux-kernel
      den.aspects.hardware.endgame
    ];

    nixos = { ... }: {
      imports = [ ./_disko.nix ];
    };
  };
}
