{
  lib,
  config,
  inputs,
  ...
}:
{
  options.nixpkgs.config = {
    allowUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
      description = "Explicit list of unfree package names permitted in any nixosConfiguration.";
    };
  };

  config.flake.modules.nixos.base =
    nixosArgs:
    let
      allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) config.nixpkgs.config.allowUnfreePackages;
    in
    {
      nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;

      # Explicit second nixpkgs instance, exposed to NixOS modules as `pkgs-stable`.
      _module.args.pkgs-stable = import inputs.nixpkgs-stable {
        inherit (nixosArgs.config.nixpkgs.hostPlatform) system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };
    };
}
