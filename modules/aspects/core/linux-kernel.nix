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
          # 'server' is the one value that ignores channel, since upstream only
          # ships linuxPackages-cachyos-server-lto. The assertion below makes
          # that combination fail loudly instead of handing a host a kernel it
          # didn't ask for.
          kernelName =
            if optimization == "server" then
              "linuxPackages-cachyos-server-lto"
            else if optimization == "generic" then
              "linuxPackages-cachyos-${channel}"
            else
              "linuxPackages-cachyos-${channel}-${optimization}";
        in
        {
          assertions = [
            {
              assertion = optimization != "server" || channel == "latest";
              message = "host ${host.name}: linux-kernel.optimization = \"server\" ignores linux-kernel.channel (there is only linuxPackages-cachyos-server-lto), but channel is set to \"${channel}\". Drop the channel setting or pick a different optimization.";
            }
          ];

          nixpkgs.overlays = [
            inputs.nix-cachyos-kernel.overlays.pinned
          ];

          # Trusts attic.xuyh0120.win/lantian for prebuilt kernels. Only
          # endgame takes this aspect, and endgame is my Secure Boot host, so
          # a bad cache could hand it a kernel its own boot chain would
          # happily sign. I'll take that over compiling a zen4 LTO kernel on
          # every bump.
          nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
          nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

          boot.kernelPackages = pkgs.cachyosKernels.${kernelName};
        };
    };
}
