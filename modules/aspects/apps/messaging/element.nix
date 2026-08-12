_: {
  megadots.apps.messaging.element = {
    description = "The Element Matrix client.";

    home-persist.directories = [ ".config/Element" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.element-desktop ];
      };
  };
}
