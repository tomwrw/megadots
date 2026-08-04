_: {
  den.aspects.apps.security.ente-auth.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-auth ];
    };
}
