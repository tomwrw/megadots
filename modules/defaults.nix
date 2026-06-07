{
  den,
  inputs,
  lib,
  ...
}:
{
  den.default = {
    includes = [
      den.batteries.define-user
      den.batteries.hostname
      den.batteries.inputs'
      den.batteries.self'
    ];

    nixos =
      {
        pkgs,
        config,
        ...
      }:
      {
        home-manager.backupFileExtension = "hm-backup";
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;
      };
  };
}
