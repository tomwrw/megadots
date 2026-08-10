_: {
  den.aspects.apps.gaming.minecraft.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.prismlauncher
      ];

      home.persistence."/persist".directories = [ ".local/share/PrismLauncher" ];
    };
}
