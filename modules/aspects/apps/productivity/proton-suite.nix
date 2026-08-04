_: {
  den.aspects.apps.productivity.proton-suite.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.proton-pass
        pkgs.proton-vpn
      ];
    };
}
