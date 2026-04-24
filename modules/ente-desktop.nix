{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-desktop ];
    };
}
