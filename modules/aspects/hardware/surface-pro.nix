{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware = {
    url = "github:nixos/nixos-hardware";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.hardware.surface-pro.nixos =
    { config, lib, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel ];

      # Restated here because nixos-hardware sets it as
      # 'mkDefault [ "mem_sleep_default=deep" ]', and a mkDefault list definition
      # of boot.kernelParams is ALWAYS discarded: nixpkgs' own kernel.nix
      # contributes "loglevel=4" at normal priority on every NixOS system, and
      # filterOverrides drops every lower-priority definition of a list option
      # before merging. So the upstream default never applies anywhere, and
      # without this line the Surface loses S0ix "Modern Standby" and drains
      # its battery overnight.
      boot.kernelParams = [ "mem_sleep_default=deep" ];

      # The line above is the whole reason this aspect is more than an import,
      # and its failure mode is a laptop that quietly eats its battery rather
      # than anything that errors. Asserted here rather than in
      # modules/flake/checks.nix so the guard travels with the aspect and
      # applies to any future Surface host without being registered anywhere.
      assertions = [
        {
          assertion = lib.elem "mem_sleep_default=deep" config.boot.kernelParams;
          message = "hardware.surface-pro: mem_sleep_default=deep is missing from boot.kernelParams - S0ix standby is broken and the battery will drain overnight. Something is defining boot.kernelParams at a higher priority (mkForce?).";
        }
      ];
    };
}
