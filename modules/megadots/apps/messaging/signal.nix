_: {
  megadots.apps.messaging.signal = {
    description = "Signal Desktop.";

    home-persist.directories = [ ".config/Signal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.signal-desktop ];
      };
  };
}
