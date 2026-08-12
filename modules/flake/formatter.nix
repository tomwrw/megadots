{ inputs, ... }:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = {
    treefmt = {
      programs.nixfmt.enable = true;
      programs.statix.enable = true;

      programs.deadnix = {
        enable = true;
        # The one deadnix rule this repo can't have. den dispatches on the
        # *names* of a function's formal arguments, so an argument the body
        # never mentions is still load-bearing:
        #
        #   pipe.collectAll ({ host, ... }: true)
        #
        # names the entity kinds the stage is allowed to match. deadnix sees an
        # unused pattern name and rewrites it to (_: true), which matches
        # nothing, and nothing errors - the Syncthing mesh just silently loses
        # every peer. Same shape as den's config-dependent quirk thunks, where
        # the argument list is what den inspects to decide when to resolve.
        #
        # Everything else deadnix finds is still worth finding, so this turns
        # off one check rather than the tool.
        no-lambda-pattern-names = true;
      };
    };
  };
}
