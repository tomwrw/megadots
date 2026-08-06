_: {
  den.aspects.apps.messaging.element.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.element-desktop ];

      # Session and device keys; losing this drops the device out of the
      # room's verified set and re-encrypts nothing it has already seen.
      home.persistence."/persist".directories = [ ".config/Element" ];
    };
}
