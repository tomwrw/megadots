{
  den,
  inputs,
  lib,
  ...
}:
{
  den.schema.user.includes = [ den.provides.mutual-provider ];

  den.default = {
    includes = [
      den.provides.define-user
      den.provides.hostname
      # den.provides.inputs' and den.provides.self' removed: they are
      # flake-parts perSystem helpers and require `withSystem` from a
      # flake-parts mkFlake setup. Our default.nix uses bare evalModules.
      # If we later migrate to flake-parts (templates/example style),
      # add them back.
    ];

    nixos =
      {
        pkgs,
        config,
        ...
      }:
      {
        nixpkgs = {
          config = {
            allowUnfree = lib.mkDefault true;
            allowUnfreePredicate = lib.mkDefault (_: true);
          };
        };

        system.nixos.tags = [ "megadots" ];
      };
  };
}
