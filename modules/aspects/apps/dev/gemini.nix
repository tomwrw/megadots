_: {
  den.aspects.apps.dev.gemini.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.gemini-cli ];

      # Credentials and config.
      home.persistence."/persist".directories = [ ".gemini" ];
    };
}
