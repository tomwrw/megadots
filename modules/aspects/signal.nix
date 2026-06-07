{ ... }:
{
  den.aspects.signal.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.signal-desktop ];
    };
}
