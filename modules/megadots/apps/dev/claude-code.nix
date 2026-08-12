{ den, ... }:
{
  megadots.apps.dev.claude-code = {
    description = "Anthropic's Claude Code CLI.";

    includes = [ (den.batteries.unfree [ "claude-code" ]) ];

    # Holds the OAuth credentials as well as project history, so losing it
    # means logging in again, not just losing state.
    home-persist.directories = [
      ".claude"
      ".config/claude"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.claude-code
          pkgs.claude-monitor
          pkgs.nodejs
        ];
      };
  };
}
