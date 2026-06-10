_: {
  den.aspects.code-cursor = {
    unfree = [ "cursor" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.code-cursor ];
      };
  };
}
