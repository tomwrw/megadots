_: {
  megadots.apps.security.ente-auth = {
    description = "Ente Auth, a TOTP authenticator.";

    home-persist.directories = [ ".local/share/io.ente.auth" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ente-auth ];
      };
  };
}
