_: {
  den.aspects.minecraft.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.prismlauncher
      ];
    };
}
