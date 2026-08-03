_: {
  den.aspects.apps.productivity.joplin.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.joplin
        pkgs.joplin-desktop
      ];
    };
}
