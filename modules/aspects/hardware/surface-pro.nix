{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware = {
    url = "github:nixos/nixos-hardware";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.hardware.surface-pro.nixos = {
    imports = [ inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel ];

    # Restated here because nixos-hardware sets it as
    # `mkDefault [ "mem_sleep_default=deep" ]`, and a mkDefault list definition
    # of boot.kernelParams is ALWAYS discarded: nixpkgs' own kernel.nix
    # contributes "loglevel=4" at normal priority on every NixOS system, and
    # filterOverrides drops every lower-priority definition of a list option
    # before merging. So the upstream default never applies anywhere, and
    # without this line the Surface loses S0ix "Modern Standby" and drains
    # its battery overnight.
    boot.kernelParams = [ "mem_sleep_default=deep" ];
  };
}
