{ ... }:
{
  den.aspects.ghostty.homeManager =
    { ... }:
    {
      programs.ghostty = {
        enable = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
    };
}
