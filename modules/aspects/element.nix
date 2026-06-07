{ ... }:
{
  den.aspects.element.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.element-desktop ];
    };
}
