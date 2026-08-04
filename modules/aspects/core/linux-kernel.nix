{ inputs, ... }:
{
  flake-file.inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

  den.aspects.core.linux-kernel =
    { host, ... }:
    {
      nixos =
        { pkgs, ... }:
        let
          inherit (host.linux-kernel) channel optimization;
          kernelName =
            if optimization == "server" then
              "linuxPackages-cachyos-server-lto"
            else if optimization == "generic" then
              "linuxPackages-cachyos-${channel}"
            else
              "linuxPackages-cachyos-${channel}-${optimization}";
        in
        {
          nixpkgs.overlays = [
            inputs.nix-cachyos-kernel.overlays.pinned
          ];

          # Trusts attic.xuyh0120.win/lantian to supply pre-built kernel
          # binaries. This aspect is only included on endgame - the one
          # Secure Boot (lanzaboote) host - so a compromised cache could
          # hand it a kernel that its own boot chain would still sign and
          # boot without complaint. Accepted trade-off for not compiling
          # zen4/LTO kernels locally on every kernel bump.
          nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
          nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

          boot.kernelPackages = pkgs.cachyosKernels.${kernelName};
        };
    };
}
