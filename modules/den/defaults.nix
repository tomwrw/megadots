{
  den,
  ...
}:
{
  den.default = {
    includes = [
      den.batteries.define-user
      den.batteries.hostname
    ];

    # Parametric on host so system.stateVersion comes from the roster rather
    # than being one number every machine inherits - see den/schema.nix. The
    # nixos class only ever resolves at host scope, so host is always present
    # here.
    nixos =
      { host, ... }:
      {
        system.stateVersion = host.stateVersion;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;
      };

    homeManager.home.stateVersion = "26.05";
  };
}
