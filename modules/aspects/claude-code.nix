_: {
  den.aspects.claude-code = {
    unfree = [ "claude-code" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.claude-code
          pkgs.claude-monitor
        ];
      };
  };
}
