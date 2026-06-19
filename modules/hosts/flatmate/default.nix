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
        # hostName comes from the hostname battery (host entity name);
        # stateVersion from den.default.
        networking = {
          domain = "home.arpa";
          search = [ "home.arpa" ];
        };
      };
  };
}
