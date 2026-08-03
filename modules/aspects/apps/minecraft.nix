_: {
  den.aspects.apps.gaming.minecraft.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.prismlauncher
      ];
    };
}
