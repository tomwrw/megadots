_: {
  den.aspects.apps.productivity.joplin.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.joplin
        pkgs.joplin-desktop
      ];

      # UNVERIFIED: notebooks and sync state. Check 'ls ~/.config' after
      # first run.
      home.persistence."/persist".directories = [ ".config/joplin-desktop" ];
    };
}
