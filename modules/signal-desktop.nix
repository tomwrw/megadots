{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.signal-desktop ];
    };
}
