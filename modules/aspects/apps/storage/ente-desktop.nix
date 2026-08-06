_: {
  den.aspects.apps.storage.ente-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ente-desktop ];

      # UNVERIFIED. Lower urgency than ente-auth: the library is cloud-backed,
      # so a wrong path costs a re-login and a re-sync, not data.
      home.persistence."/persist".directories = [ ".config/ente-desktop" ];
    };
}
