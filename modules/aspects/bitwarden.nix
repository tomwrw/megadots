{ ... }:
{
  den.aspects.bitwarden.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-cli ];
    };
}
