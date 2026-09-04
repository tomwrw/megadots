{ den, ... }:
{
  den.aspects.flatmate = {
    includes = [
      # Roles
      den.aspects.base
      den.aspects.workstation
      den.aspects.dev

      # The choices only this machine makes
      den.aspects.boot.systemd-boot
      den.aspects.gnome
      den.aspects.surface-pro
    ];

    # See the note in hosts/endgame/default.nix.
    nixos.imports = [ ./_hardware.nix ];
  };
}
