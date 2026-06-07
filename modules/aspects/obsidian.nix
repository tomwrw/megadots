{ ... }:
{
  den.aspects.obsidian.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.obsidian ];
    };
}
