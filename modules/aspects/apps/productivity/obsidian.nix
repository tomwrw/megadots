_: {
  den.aspects.apps.productivity.obsidian = {
    unfree = [ "obsidian" ];

    # programs.obsidian rather than home.packages: the HM module is what
    # Stylix's obsidian target injects its CSS snippet through, so the bare
    # package would silently forfeit the theming.
    homeManager = _: {
      programs.obsidian.enable = true;

      home.persistence."/persist".directories = [
        # The vault itself. desktop/stylix.nix points its obsidian target at
        # ~/Sync/Notes, so that whole tree has to survive - losing it loses
        # the notes, not just app state.
        #
        # NOTE: this is ~/Sync, not the ~/Syncthing folder core.syncthing
        # replicates. Those are two different directories today; if the vault
        # is meant to be synced, one of the two paths is wrong.
        "Sync"
        # UNVERIFIED: app state (workspace layout, installed community
        # plugins, per-vault settings). Confirm with `ls ~/.config` after
        # first run.
        ".config/obsidian"
      ];
    };
  };
}
