{ den, ... }:
{
  megadots.apps.dev.code-cursor = {
    description = "The Cursor editor.";

    includes = [ (den.batteries.unfree [ "cursor" ]) ];

    home-persist.directories = [ ".config/Cursor" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.code-cursor ];
      };
  };
}
