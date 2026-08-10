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

    nixos = {
      system.stateVersion = "26.05";
      home-manager.backupFileExtension = "hm-backup";
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
    };

    homeManager.home.stateVersion = "26.05";
  };
}
