{ ... }:
{
  den.aspects.gemini.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.gemini-cli ];
    };
}
