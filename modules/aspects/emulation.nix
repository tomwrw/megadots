_: {
  den.aspects.emulation.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.ryubing
        pkgs.cemu
      ];
    };
}
