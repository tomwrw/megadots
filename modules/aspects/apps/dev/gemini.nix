_: {
  megadots.apps.dev.gemini = {
    description = "Google's Gemini CLI.";

    # Credentials and config.
    home-persist.directories = [ ".gemini" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gemini-cli ];
      };
  };
}
