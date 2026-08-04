_: {
  den.aspects.apps.storage.ente-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-desktop ];
    };
}
