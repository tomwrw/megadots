_: {
  # Signal Desktop.
  den.aspects.signal = {
    persist.home.directories = [ ".config/Signal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.signal-desktop ];
      };
  };
}
