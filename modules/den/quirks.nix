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

  den.quirks.persist = {
    description = "Extra paths to persist at /persist: { directories, files }";
  };
}
