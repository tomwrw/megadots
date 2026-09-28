_: {
  # The Tuta (formerly Tutanota) mail desktop client.
  den.aspects.tutanota-desktop = {
    persist.home.directories = [ ".config/tutanota-desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.tutanota-desktop ];
      };
  };
}
