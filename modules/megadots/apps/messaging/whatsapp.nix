_: {
  megadots.apps.messaging.whatsapp = {
    description = "A WhatsApp desktop client.";

    home-persist.directories = [ ".local/share/karere" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.karere ];
      };
  };
}
