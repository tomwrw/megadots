{ den, inputs, ... }:
{
  flake-file.inputs.nixos-hardware = {
    url = "github:nixos/nixos-hardware";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.flatmate = {
    includes = [
      den.aspects.base
      den.aspects.desktop
      den.aspects.preservation
    ];

    nixos =
      { ... }:
      {
        imports = [
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
          ./_disko.nix
          ./_hardware.nix
        ];
        # Set the host-specific hostname here.
        networking = {
          hostName = "flatmate";
          domain = "home.arpa";
          search = [ "home.arpa" ];
        };
        # Set the system state version.
        system.stateVersion = "26.05";
      };
  };
}
