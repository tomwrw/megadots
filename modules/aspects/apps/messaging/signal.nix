_: {
  den.aspects.apps.messaging.signal.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.signal-desktop ];

      # Session/device-link state; losing this forces re-linking as a new
      # device, which also loses the local message history.
      home.persistence."/persist".directories = [ ".config/Signal" ];
    };
}
