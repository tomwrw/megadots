{ den, ... }:
{
  den.aspects.endgame = {
    includes = [
      den.aspects.base
      den.aspects.desktop
      den.aspects.secure-boot
      den.aspects.gaming
      den.aspects.virtualisation
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
