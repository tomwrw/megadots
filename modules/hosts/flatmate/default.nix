{ den, ... }:
{
  den.aspects.flatmate = {
    includes = [
      den.aspects.roles.base
      den.aspects.roles.workstation
      den.aspects.core.boot.systemd-boot
      den.aspects.hardware.surface-pro
    ];

    # See the note in hosts/endgame/default.nix.
    nixos.imports = [ ./_hardware.nix ];
  };
}
