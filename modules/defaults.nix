{
  den,
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

    # Both hosts were installed at 26.05. Override per-host if a future
    # machine is installed at a different version.
    nixos = {
      system.stateVersion = "26.05";
      home-manager.backupFileExtension = "hm-backup";
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
    };

    homeManager.home.stateVersion = "26.05";
  };
}
