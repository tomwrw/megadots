{ lib, ... }:
{
  # The Ghostty terminal emulator.
  den.aspects.ghostty = {
    # This is the terminal, for anything that needs to wrap a command in a
    # window - see the terminal quirk in den/quirks.nix. "-e" is ghostty's way
    # of saying "run this instead of a shell"; a different terminal spells it
    # differently, which is exactly why the spelling lives here and not in the
    # aspects that consume it.
    #
    # A function of pkgs, applied by the consumer where pkgs is in scope.
    terminal.exec = pkgs: "${lib.getExe pkgs.ghostty} -e";

    homeManager = _: {
      # Shell integration is already on through home.shell.enableShellIntegration,
      # so I don't repeat it here.
      programs.ghostty.enable = true;
    };
  };
}
