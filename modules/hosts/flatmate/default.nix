{ den, ... }:
{
  den.aspects.flatmate = {
    includes = [
      den.aspects.base
      den.aspects.fonts
      den.aspects.gnome
      den.aspects.preservation
    ];

    nixos =
      { ... }:
      {
        imports = [
          ./_disko.nix
          ./_hardware.nix
        ];
        networking.hostName = "flatmate";
        system.stateVersion = "26.05";
      };
  };
}
