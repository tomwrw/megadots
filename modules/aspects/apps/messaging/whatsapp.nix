_: {
  den.aspects.apps.messaging.whatsapp.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.karere ];

      home.persistence."/persist".directories = [ ".local/share/karere" ];
    };
}
