_: {
  # Ente Auth, a TOTP authenticator.
  den.aspects.ente-auth = {
    persist.home.directories = [ ".local/share/io.ente.auth" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ente-auth ];
      };
  };
}
