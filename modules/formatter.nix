{ inputs, ... }:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.treefmt-nix.flakeModule ];

  # Provides `nix fmt` (flake formatter output) and a `checks.treefmt`
  # gate for `nix flake check`.
  perSystem = {
    treefmt = {
      programs.nixfmt.enable = true;
      programs.deadnix.enable = true;
      programs.statix.enable = true;
    };
  };
}
