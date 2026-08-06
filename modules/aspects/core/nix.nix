{ inputs, ... }:
{
  den.aspects.core.nix.nixos =
    { lib, ... }:
    {
      nix = {
        # Makes 'nix run nixpkgs#...' use the same nixpkgs the system was built
        # from.
        #
        # Only nixpkgs. Mapping every input pulls each one's source into the
        # system closure, which then gets pushed on every rebuild and held for
        # the 30 day GC window. That's a few hundred MB to register flake refs
        # I never type.
        registry.nixpkgs.flake = inputs.nixpkgs;

        settings = {
          # See https://jackson.dev/post/nix-reasonable-defaults/ for
          # explanation of sensible defaults.
          connect-timeout = 5;
          log-lines = 25;
          # Trust wheel so 'nixos-rebuild --target-host' can push closures I
          # built locally to my other hosts. Single admin, LAN only.
          trusted-users = [
            "root"
            "@wheel"
          ];
          # Hard-link identical store paths as they're written instead of
          # running nix.optimise later. Slightly slower builds, but I never
          # have to remember to run it.
          auto-optimise-store = true;

          # Leave IFD on. Stylix reads its base16 scheme yaml out of a
          # derivation at eval time, so turning this off breaks the theming.
          allow-import-from-derivation = true;

          warn-dirty = false;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          max-jobs = "auto";
          cores = 0;
          show-trace = true;
          sandbox = true;
          keep-build-log = true;
          fallback = true;

          # Free space mid-build once under 512MB, up to 1GB. mkDefault so a
          # host with a small disk can lower it.
          min-free = lib.mkDefault 536870912;
          max-free = lib.mkDefault 1073741824;
        };
        # Automatically clean up stale generations and store paths.
        gc = {
          automatic = true;
          dates = "weekly";
          # Delete generations older than 30 days.
          options = "--delete-older-than 30d";
        };
      };

      programs.nix-ld.enable = true;
    };
}
