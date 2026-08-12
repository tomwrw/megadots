_: {
  megadots.apps.storage.ente-desktop = {
    description = "The Ente photo storage client.";

    home-persist.directories = [ ".config/ente" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ente-desktop ];
      };
  };
}
