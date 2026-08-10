_: {
  den.aspects.apps.messaging.signal.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.signal-desktop ];

      home.persistence."/persist".directories = [ ".config/Signal" ];
    };
}
