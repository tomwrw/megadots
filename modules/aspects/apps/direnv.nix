_: {
  # direnv, so entering a project directory loads its environment.
  #
  # This exists because apps/neovim.nix turned on nvf's direnv plugin, which is
  # only the direnv.vim wrapper - it shells out to a direnv binary that nothing
  # here installed, so every file opened printed "no direnv executable found".
  # Anything else looking for it, VSCodium included, failed the same way for the
  # same reason.
  den.aspects.direnv = {
    # The allow list, and the only state direnv keeps. It writes one file per
    # approved .envrc under $XDG_DATA_HOME/direnv/allow - verified against
    # direnv 2.37, which put .local/share/direnv/allow/<hash> there on a test
    # 'direnv allow'. Without this, / going back to a blank snapshot every boot
    # means every project asks to be approved again.
    persist.home.directories = [ ".local/share/direnv" ];

    homeManager = _: {
      programs.direnv = {
        enable = true;

        # Caches the flake's dev shell and keeps a GC root for it, so a cd into
        # a project is instant instead of a fresh evaluation, and the closure
        # survives the weekly nix.gc in core/nix.nix. The cache lives in a
        # .direnv directory inside the project itself, which for everything I
        # work on is under ~/Syncthing - already persisted by apps/syncthing.nix.
        nix-direnv.enable = true;
      };

      # No shell hook here. enableZshIntegration defaults on whenever zsh is
      # enabled, and Home Manager writes the hook into programs.zsh.initContent
      # itself - the same reason apps/shell.nix does not repeat what
      # den.batteries.user-shell already turned on.
    };
  };
}
