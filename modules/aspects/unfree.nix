{ den, ... }:
{
  # Unfree packages are allowed per-name, never globally. An aspect that
  # ships an unfree package declares it via this quirk, e.g.
  #   den.aspects.obsidian.unfree = [ "obsidian" ];
  # and the predicate below admits exactly the collected names.
  den.quirks.unfree = {
    description = "Unfree package names (lib.getName) an aspect requires";
  };

  # Quirk values set by user-included aspects live in the user scope;
  # expose them upward so the host-level consumer below sees them too.
  # Policies only take effect where they are included, hence the schema
  # include applying this to every user.
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
