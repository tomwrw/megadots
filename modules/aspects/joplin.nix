_: {
  den.aspects.joplin.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.joplin
        pkgs.joplin-desktop
      ];
    };
}
