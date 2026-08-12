{ den, megadots, ... }:
{
  den.aspects.flatmate = {
    includes = [
      den.aspects.roles.base
      den.aspects.roles.workstation
      den.aspects.roles.dev
      megadots.core.boot.systemd-boot
      megadots.hardware.surface-pro
    ];

    # See the note in hosts/endgame/default.nix.
    nixos.imports = [ ./_hardware.nix ];
  };
}
