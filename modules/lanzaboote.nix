# Secure Boot input wiring: pulls in the lanzaboote flake and imports its
# NixOS module into the `secure-boot` aspect. The actual Secure Boot policy
# (enabling lanzaboote, disabling systemd-boot, key persistence) lives in
# aspects/secure-boot.nix — both files contribute to den.aspects.secure-boot.
{ inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.secure-boot.nixos.imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
}
