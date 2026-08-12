_: {
  megadots.apps.messaging.vesktop = {
    description = "Vesktop, an alternative Discord client.";

    home-persist.directories = [ ".config/vesktop" ];

    homeManager = _: {
      programs.vesktop.enable = true;
    };
  };
}
