_: {
  den.aspects.apps.dev.gemini.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.gemini-cli ];
    };
}
