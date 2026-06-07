{ inputs, ... }:
{
  flake-file.inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

  den.aspects.kernel.nixos =
    { pkgs, lib, ... }:
    {
      boot.kernelPackages =
        lib.mkForce
          inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-latest;

      # Binary caches for the prebuilt CachyOS kernel — `extra-` so they append
      # to (never replace) the default substituters incl. cache.nixos.org. These
      # live here (the aspect that needs them) rather than the general nix aspect.
      nix.settings = {
        extra-substituters = [
          "https://attic.xuyh0120.win/lantian"
          "https://cache.garnix.io"
        ];
        extra-trusted-public-keys = [
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
      };
    };
}
