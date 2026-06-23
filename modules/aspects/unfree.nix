{ den, ... }:
{
  den.quirks.unfree = {
    description = "Unfree package names (lib.getName) an aspect requires";
  };

  den.policies.unfree =
    _:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "unfree" [ pipe.expose ]) ];

  den.schema.user.includes = [ den.policies.unfree ];

  den.aspects.unfree.nixos =
    { unfree, lib, ... }:
    {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfree;
    };
}
