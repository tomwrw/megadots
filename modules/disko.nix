# Declarative disk partitioning via disko. Input wiring + module import; the
# per-host disk layout lives in modules/hosts/<host>/_disko.nix. Pulled in for
# every NixOS host via den.aspects.base.
{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.disko.nixos.imports = [ inputs.disko.nixosModules.disko ];
}