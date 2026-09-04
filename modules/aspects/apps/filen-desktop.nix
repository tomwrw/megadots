_: {
  # The Filen encrypted storage client.
  den.aspects.filen-desktop = {
    persist.home.directories = [ ".config/@filen" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.filen-desktop ];
      };
  };
}
