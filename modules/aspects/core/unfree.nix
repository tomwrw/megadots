_: {
  den.aspects.core.unfree.nixos =
    { unfree, lib, ... }:
    {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfree;
    };
}
