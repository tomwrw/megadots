_: {
  den.aspects.apps.gaming.minecraft.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.prismlauncher
      ];

      # UNVERIFIED: instances, mod loaders and the Mojang account token.
      # Confirm with `ls ~/.local/share` after first run.
      home.persistence."/persist".directories = [ ".local/share/PrismLauncher" ];
    };
}
