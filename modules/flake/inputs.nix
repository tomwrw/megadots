{ inputs, lib, ... }:
let
  flake-description = "megadots - a denful NixOS and Home Manager configuration by tomwrw.";
  flake-comment = lib.concatStringsSep "\n" [
    "# For those who come after..."
    "# Re-generate this flake by running 'nix run .#write-flake'."
  ];
in
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  flake-file.inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-file.url = "github:vic/flake-file";
    den.url = "github:denful/den";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Words. Because why not.
  flake-file = {
    description = flake-description;
    do-not-edit = flake-comment;
  };
}
