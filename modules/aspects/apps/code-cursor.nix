_: {
  den.aspects.apps.dev.code-cursor = {
    unfree = [ "cursor" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.code-cursor ];
      };
  };
}
