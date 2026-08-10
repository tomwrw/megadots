_: {
  den.aspects.apps.messaging.vesktop.homeManager = _: {
    programs.vesktop.enable = true;

    home.persistence."/persist".directories = [ ".config/vesktop" ];
  };
}
