{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.proton-vpn ];
    };
}
