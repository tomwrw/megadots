_: {
  den.aspects.apps.productivity.obsidian = {
    unfree = [ "obsidian" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.obsidian ];
      };
  };
}
