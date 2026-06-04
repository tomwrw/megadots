{ den, ... }:
{
  den.aspects.endgame = {
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
        # Set the host-specific hostname here.
        networking = {
          hostName = "endgame";
          domain = "home.arpa";
        };
        # Set the system state version.
        system.stateVersion = "26.05";
      };
  };
}
