{
  config,
  inputs,
  ...
}:
let
  owner = config.flake.meta.owner;
in
{
  flake-file.inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos = {
    base = {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        verbose = true;
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";

        users.${owner.username}.imports = [
          (
            { osConfig, ... }:
            {
              home.stateVersion = osConfig.system.stateVersion;
            }
          )
          config.flake.modules.homeManager.base
        ];
      };
    };

    pc = {
      home-manager.users.${owner.username}.imports = [
        config.flake.modules.homeManager.pc
      ];
    };

    gaming = {
      home-manager.users.${owner.username}.imports = [
        config.flake.modules.homeManager.gaming
      ];
    };
  };
}
