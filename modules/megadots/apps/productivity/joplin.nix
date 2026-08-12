_: {
  megadots.apps.productivity.joplin = {
    description = "The Joplin desktop note client.";

    # UNVERIFIED: notebooks and sync state. Check 'ls ~/.config' after
    # first run.
    home-persist.directories = [ ".config/joplin-desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.joplin
          pkgs.joplin-desktop
        ];
      };
  };
}
