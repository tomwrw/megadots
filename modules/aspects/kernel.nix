{ lib, inputs, ... }:
{
  flake-file.inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

  den.aspects.system.linux-kernel = {
    settings = {
      channel = lib.mkOption {
        type = lib.types.enum [
          "lts"
          "latest"
        ];
        default = "latest";
        description = "CachyOS kernel release channel";
      };
      optimization = lib.mkOption {
        type = lib.types.enum [
          "server"
          "generic"
          "zen4"
          "x86_64-v4"
        ];
        default = "generic";
        description = ''
          CachyOS kernel optimization target. "generic" builds an unoptimized
          (no -march) kernel that runs on any x86_64 CPU; the safe base default.
          "x86_64-v4" needs AVX-512 and "zen4" is AMD Zen 4 only.
        '';
      };
    };

    nixos =
      { host, pkgs, ... }:
      let
        # Hosts that include this aspect via base but set no kernel settings
        # (e.g. flatmate) have no host.settings, so fall back to the defaults.
        cfg = host.settings.system.linux-kernel or { };
        channel = cfg.channel or "latest";
        optimization = cfg.optimization or "generic";
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

        nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
        nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

        # mkDefault so a hardware profile that ships its own kernel (e.g. the
        # microsoft-surface module on flatmate) takes precedence. Hosts without
        # a competing definition (endgame) still get the CachyOS kernel.
        boot.kernelPackages = lib.mkDefault pkgs.cachyosKernels.${kernelName};
      };
  };
}
