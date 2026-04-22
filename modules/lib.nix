{
  lib,
  config,
  inputs,
  ...
}: {
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
  };

  config.flake.lib.mkNixos = system: name: {
    ${name} = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [config.flake.modules.nixos.${name}];
    };
  };
}
