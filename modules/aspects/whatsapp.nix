{ ... }:
{
  den.aspects.whatsapp.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.karere ];
    };
}
