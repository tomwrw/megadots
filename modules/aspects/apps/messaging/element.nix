_: {
  den.aspects.apps.messaging.element.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.element-desktop ];
    };
}
