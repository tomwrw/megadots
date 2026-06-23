_: {
  den.aspects.ente-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-desktop ];
    };
}
