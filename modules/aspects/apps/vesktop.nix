_: {
  # Vesktop, an alternative Discord client.
  den.aspects.vesktop = {
    persist.home.directories = [ ".config/vesktop" ];

    homeManager = _: {
      programs.vesktop.enable = true;
    };
  };
}
