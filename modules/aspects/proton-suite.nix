{ ... }:
{
  den.aspects.proton-suite.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.proton-pass
        pkgs.proton-vpn
      ];
    };
}
