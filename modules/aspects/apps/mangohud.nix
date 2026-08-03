_: {
  den.aspects.apps.gaming.mangohud.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.mangohud ];
    };
}
