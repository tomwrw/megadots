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
      den.provides.inputs'
      den.provides.self'
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
