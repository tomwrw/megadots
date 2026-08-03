{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware = {
    url = "github:nixos/nixos-hardware";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.hardware.surface-pro.nixos.imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
  ];
}
