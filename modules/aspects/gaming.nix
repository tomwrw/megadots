{ ... }:
{
  den.aspects.gaming = {
    nixos =
      { ... }:
      {
        programs.steam.enable = true;
        services.sunshine.enable = true;
        hardware.graphics.enable32Bit = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.mangohud
        ];
      };
  };
}
