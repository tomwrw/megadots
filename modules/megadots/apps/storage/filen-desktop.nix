_: {
  megadots.apps.storage.filen-desktop = {
    description = "The Filen encrypted storage client.";

    home-persist.directories = [ ".config/@filen" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.filen-desktop ];
      };
  };
}
