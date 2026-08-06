_: {
  den.aspects.apps.security.ente-auth.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-auth ];

      # UNVERIFIED, and the highest blast radius in this inventory: these are
      # the TOTP secrets. Confirm with `ls ~/.config` after first run, before
      # relying on this host for second factors.
      home.persistence."/persist".directories = [ ".config/ente-auth" ];
    };
}
