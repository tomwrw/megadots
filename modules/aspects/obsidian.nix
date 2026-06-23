_: {
  den.aspects.obsidian = {
    unfree = [ "obsidian" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.obsidian ];
      };
  };
}
