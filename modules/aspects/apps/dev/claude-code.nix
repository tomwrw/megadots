_: {
  den.aspects.apps.dev.claude-code = {
    unfree = [ "claude-code" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.claude-code
          pkgs.claude-monitor
          pkgs.nodejs
        ];

        # Holds the OAuth credentials as well as project history, so losing
        # it means logging in again, not just losing state.
        home.persistence."/persist".directories = [
          ".claude"
          ".config/claude"
        ];
      };
  };
}
