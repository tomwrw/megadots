_: {
  den.aspects.apps.dev.vscodium.homeManager = _: {
    programs.vscodium.enable = true;

    # Extension-internal state - auth tokens, recently-opened, workspace
    # storage - none of which the declarative settings cover.
    home.persistence."/persist".directories = [ ".config/VSCodium" ];
  };
}
