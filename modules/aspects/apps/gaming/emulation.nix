_: {
  den.aspects.apps.gaming.emulation.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.ryubing
        pkgs.cemu
      ];
    };
}
