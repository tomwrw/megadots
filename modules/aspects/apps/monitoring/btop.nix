_: {
  den.aspects.apps.monitoring.btop.homeManager = _: {
    programs.btop.enable = true;

    # Nothing to persist: the config is written by Home Manager (and themed by
    # Stylix) on every activation, and btop keeps no other state.
  };
}
