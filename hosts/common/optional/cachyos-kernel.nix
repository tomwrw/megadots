{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  boot.kernelPackages =
    lib.mkForce
      inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-latest;

  # Binary cache for the prebuilt CachyOS kernel — without these
  # the kernel rebuilds locally on every change.
  nix.settings = {
    substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };
}
