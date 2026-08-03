{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.disko.nixos.imports = [ inputs.disko.nixosModules.disko ];
}
