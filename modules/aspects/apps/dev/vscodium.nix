_: {
  den.aspects.apps.dev.vscodium.homeManager = _: {
    programs.vscodium.enable = true;

    # Extension state: auth tokens, recently opened, workspace storage. None
    # of it covered by the declarative settings.
    home.persistence."/persist".directories = [ ".config/VSCodium" ];
  };
}
