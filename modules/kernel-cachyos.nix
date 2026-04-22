{inputs, ...}: {
  flake-file.inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  flake.modules.nixos.pc = {pkgs, ...}: {
    boot.kernelPackages =
      inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-latest;

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
  };
}
