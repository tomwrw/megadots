_: {
  # The shell itself, independent of which shell it is.
  #
  # home.shellAliases and not programs.zsh.shellAliases: Home Manager fans the
  # former out to bash, zsh, fish and nushell, so an alias written once follows
  # me onto whatever I run next. Nothing changes today - zsh is the only shell
  # enabled - but a future apps/fish.nix declaring
  # den.aspects.shell.provides.fish would get this set for free, and unlike the
  # boot sub-aspects these are not alternatives: including shell.zsh and
  # shell.fish together is fine.
  #
  # A provides child does NOT inherit its parent, so users/tomwrw includes both
  # den.aspects.shell and den.aspects.shell.zsh. Same shape as roles/base.nix
  # taking den.aspects.boot while each host takes its own boot.<loader>.
  #
  # Only the aliases with nowhere better to be live here. Everything else sits
  # with the tool it drives - git in apps/git.nix, nix in core/nix.nix, where
  # the latter can name the host it rebuilds.
  den.aspects.shell.homeManager = {
    home.shellAliases = {
      # ls, ll, la, lla and lt come from programs.eza in apps/cli-apps.nix.
      psf = "ps -aux | grep";
      lsf = "ls | grep";
    };
  };
}
