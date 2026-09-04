_: {
  # The Ghostty terminal emulator.
  den.aspects.ghostty.homeManager = _: {
    # Shell integration is already on through home.shell.enableShellIntegration,
    # so I don't repeat it here.
    programs.ghostty.enable = true;
  };
}
