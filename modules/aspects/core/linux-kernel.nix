{ inputs, den, ... }:
{
  flake-file.inputs.chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

  # A CachyOS kernel from chaotic-cx/nyx, which is also where apps/steam.nix
  # gets proton-cachyos: one input, one cache, one set of build flags across
  # both. Which kernel is the host's choice - see den.schema.host.
  den.aspects.linux-kernel =
    { host, ... }:
    {
      includes = [ den.aspects.nyx-cache ];

      nixos =
        { pkgs, ... }:
        {
          # The linuxPackages_cachyos-* sets live in nyx's overlay, not in its
          # packages output. The module defaults to building them against nyx.s
          # own nixpkgs pin rather than this flake.s, which is what makes the
          # cache hit at all - overriding it means compiling.
          imports = [ inputs.chaotic.nixosModules.nyx-overlay ];

          # Trusting a third-party cache for the kernel, on the host whose
          # Secure Boot chain then signs whatever it boots. Accepted so that a
          # znver4 LTO kernel does not have to be compiled locally on every bump.
          boot.kernelPackages = pkgs."linuxPackages_cachyos-${host.linux-kernel.variant}";
        };
    };
}
