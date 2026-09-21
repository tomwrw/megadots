{ inputs, ... }:
{
  # chaotic-cx/nyx's binary cache, included by every aspect that takes a package
  # from it - the CachyOS kernel and proton-cachyos today.
  #
  # Its own aspect rather than an import in each of those, because den wraps
  # every aspect's nixos block as a separate module: importing nyx's module from
  # two of them declares chaotic.nyx.cache.enable twice and eval dies. One
  # aspect included twice is one module.
  #
  # The module carries the substituter and the key from nyx's own nixConfig, so
  # neither is copied into this repo to go stale.
  den.aspects.nyx-cache.nixos.imports = [ inputs.chaotic.nixosModules.nyx-cache ];
}
