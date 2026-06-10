{ inputs, ... }:
{
  # Deliberately NOT following our nixpkgs: the binary caches below hold
  # kernels built against this input's own pin. Adding a follows would
  # change the build and force compiling the kernel locally.
  flake-file.inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

  den.aspects.kernel.nixos =
    { pkgs, lib, ... }:
    {
      boot.kernelPackages =
        lib.mkForce
          inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-latest;

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
