{ ... }:
{
  den.aspects.fonts = {
    nixos =
      { pkgs, ... }:
      {
        fonts.packages = [ pkgs.jetbrains-mono ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.jetbrains-mono ];
        fonts.fontconfig.enable = true;
      };
  };
}
