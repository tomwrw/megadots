{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware = {
    url = "github:nixos/nixos-hardware";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # The nixos-hardware profile for a Microsoft Surface Pro, plus its suspend fix.
  den.aspects.surface-pro.nixos =
    { config, lib, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel ];

      # Set again here because nixos-hardware only sets it as a mkDefault, and
      # a mkDefault list definition of boot.kernelParams always gets dropped.
      # nixpkgs adds "loglevel=4" at normal priority on every system, and
      # filterOverrides throws away every lower priority definition before
      # merging. So upstream's default never applies anywhere, and without
      # this line the Surface loses modern standby and flattens its battery
      # overnight.
      boot.kernelParams = [ "mem_sleep_default=deep" ];

      # That line is the only reason this aspect isn't just an import, and it
      # fails by quietly eating the battery rather than erroring. Asserted
      # here and not in checks.nix so the guard travels with the aspect and
      # covers any Surface I add later without registering it anywhere.
      assertions = [
        {
          assertion = lib.elem "mem_sleep_default=deep" config.boot.kernelParams;
          message = "hardware.surface-pro: mem_sleep_default=deep is missing from boot.kernelParams - S0ix standby is broken and the battery will drain overnight. Something is defining boot.kernelParams at a higher priority (mkForce?).";
        }
      ];
    };
}
