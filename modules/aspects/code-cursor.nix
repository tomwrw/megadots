{ ... }:
{
  den.aspects.code-cursor.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.code-cursor ];
    };
}
