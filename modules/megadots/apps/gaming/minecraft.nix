_: {
  megadots.apps.gaming.minecraft = {
    description = "The Prism Minecraft launcher.";

    home-persist.directories = [ ".local/share/PrismLauncher" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.prismlauncher
        ];
      };
  };
}
