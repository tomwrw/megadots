_: {
  # The Prism Minecraft launcher.
  den.aspects.minecraft = {
    persist.home.directories = [ ".local/share/PrismLauncher" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.prismlauncher
        ];
      };
  };
}
