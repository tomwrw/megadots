_: {
  den.aspects.apps.security.ente-auth.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-auth ];

      home.persistence."/persist".directories = [ ".local/share/io.ente.auth" ];
    };
}
