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

        # HM runs as a NixOS module here. On a fresh deploy the home already has
        # unmanaged files (e.g. /etc/skel's .zshrc); back them up instead of
        # aborting activation when HM wants to manage the same path.
        home-manager.backupFileExtension = "hm-backup";
      };
  };
}
