{ den, ... }:
{
  # The Cursor editor.
  den.aspects.code-cursor = {
    includes = [ (den.batteries.unfree [ "cursor" ]) ];

    persist.home.directories = [ ".config/Cursor" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.code-cursor ];
      };
  };
}
