_: {
  # A WhatsApp desktop client.
  den.aspects.whatsapp = {
    persist.home.directories = [ ".local/share/karere" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.karere ];
      };
  };
}
