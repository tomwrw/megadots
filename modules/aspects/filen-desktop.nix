_: {
  den.aspects.filen-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.filen-desktop ];
    };
}
