_: {
  den.aspects.apps.messaging.whatsapp.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.karere ];

      # UNVERIFIED: karere's data directory. Confirm with `ls ~/.local/share`
      # and `ls ~/.config` after first run before trusting this path - a wrong
      # one fails silently, as a re-link prompt rather than an error.
      home.persistence."/persist".directories = [ ".local/share/karere" ];
    };
}
