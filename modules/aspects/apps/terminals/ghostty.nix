_: {
  den.aspects.apps.terminals.ghostty.homeManager = _: {
    # Shell integration is on by default via home.shell.enableShellIntegration,
    # so it is not restated here.
    programs.ghostty.enable = true;

    # Nothing to persist: the config and the Stylix theme are both regenerated
    # on activation.
  };
}
