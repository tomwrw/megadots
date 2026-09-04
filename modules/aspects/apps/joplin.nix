_: {
  # The Joplin desktop note client.
  # UNVERIFIED: notebooks and sync state. Check 'ls ~/.config' after
  den.aspects.joplin = {
    # first run.
    persist.home.directories = [ ".config/joplin-desktop" ];

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
