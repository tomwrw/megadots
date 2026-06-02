{ den, ... }:
{
  den.aspects.spectre = {
    includes = [
      den.aspects.base
      den.aspects.secure-boot
      den.aspects.fonts
      den.aspects.gnome
      den.aspects.gaming
      den.aspects.preservation
    ];

    nixos =
      { ... }:
      {
        imports = [
          ./_disko.nix
          ./_hardware.nix
        ];
        networking.hostName = "spectre";
        system.stateVersion = "26.05";
      };
  };
}
