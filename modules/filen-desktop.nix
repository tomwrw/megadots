{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.filen-desktop ];
    };
}
