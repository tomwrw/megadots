{ ... }:
{
  den.aspects.ente-auth.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-auth ];
    };
}
