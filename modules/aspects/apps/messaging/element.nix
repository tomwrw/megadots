_: {
  den.aspects.apps.messaging.element.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.element-desktop ];

      home.persistence."/persist".directories = [ ".config/Element" ];
    };
}
