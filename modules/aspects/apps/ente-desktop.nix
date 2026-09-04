_: {
  # The Ente photo storage client.
  den.aspects.ente-desktop = {
    persist.home.directories = [ ".config/ente" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ente-desktop ];
      };
  };
}
