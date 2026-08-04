_: {
  den.aspects.apps.productivity.obsidian = {
    unfree = [ "obsidian" ];

    # programs.obsidian rather than home.packages: the HM module is what
    # Stylix's obsidian target injects its CSS snippet through, so the bare
    # package would silently forfeit the theming.
    homeManager = _: {
      programs.obsidian.enable = true;
    };
  };
}
