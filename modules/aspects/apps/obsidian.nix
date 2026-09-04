{ den, ... }:
{
  # Obsidian. The vault path it is themed against is supplied by the user, not by this aspect.
  den.aspects.obsidian = {
    includes = [ (den.batteries.unfree [ "obsidian" ]) ];

    persist.home.directories = [
      ".config/obsidian"
    ];

    # programs.obsidian rather than home.packages: the HM module is what
    # Stylix's obsidian target injects its CSS snippet through, so the bare
    # package would lose the theming.
    homeManager = _: {
      programs.obsidian.enable = true;
    };
  };
}
