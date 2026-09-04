_: {
  # The Element Matrix client.
  den.aspects.element = {
    persist.home.directories = [ ".config/Element" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.element-desktop ];
      };
  };
}
