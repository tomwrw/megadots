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

        # Install HM user packages into /etc/profiles/per-user/$USER (built at
        # nixos-rebuild time) instead of ~/.nix-profile (populated only when the
        # per-user activation service runs, after the session may have started).
        # NixOS adds the per-user profile to the graphical session's PATH and
        # XDG_DATA_DIRS automatically, so wrapped apps like Firefox (which carry
        # their policies/extensions in the package) are the ones GNOME launches.
        # These options only affect HM-as-a-NixOS-module; standalone HM is
        # unaffected. useGlobalPkgs makes HM reuse the system nixpkgs (incl. the
        # allowUnfree set above) rather than evaluating its own instance.
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;
      };
  };
}
