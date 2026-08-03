{ inputs, ... }:
{
  den.aspects.core.nix.nixos =
    { lib, ... }:
    {
      nix = {
        # Make `nix run nixpkgs#…` etc. resolve flake refs to the same inputs
        # this system was built from (pinned, consistent nix3 commands).
        # Filtered to actual flakes: a `flake = false` input has no `outputs`
        # and would produce a broken registry entry.
        registry = lib.mapAttrs (_: flake: { inherit flake; }) (
          lib.filterAttrs (_: input: input ? outputs) inputs
        );

        settings = {
          # See https://jackson.dev/post/nix-reasonable-defaults/ for
          # explanation of sensible defaults.
          connect-timeout = 5;
          log-lines = 25;
          # Trust the wheel group so `nixos-rebuild --target-host` can push
          # locally-built closures to the fleet (single-admin LAN).
          trusted-users = [
            "root"
            "@wheel"
          ];
          # Deduplicate and optimise nix store.
          auto-optimise-store = true;
          # Stop telling me there are uncommited changes!
          warn-dirty = false;
          # Import-from-derivation must stay enabled: stylix's base16 scheme
          # reader readFiles a yaml from the base16-schemes derivation at eval
          # time, which is IFD. (Was the den default; do not disable.)
          allow-import-from-derivation = true;
          # Enable experimental features.
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # Build performance.
          max-jobs = "auto";
          # Use all cores if set to zero.
          cores = 0;
          # Better error messages.
          show-trace = true;
          # Sandbox builds for security.
          sandbox = true;
          # Keep build logs for debugging.
          keep-build-log = true;
          # Fallback to building if binary cache fails.
          fallback = true;
          # Prevent builds from eating all disk space.
          # 512MB min-free.
          min-free = lib.mkDefault 536870912;
          # 1GB max-free.
          max-free = lib.mkDefault 1073741824;
        };
        # Garbage collection settings to automate the process
        # of cleaning stale generations and store items.
        gc = {
          automatic = true;
          dates = "weekly";
          # Delete generations that haven't been activated in
          # over 30 days.
          options = "--delete-older-than 30d";
        };
      };

      programs.nix-ld.enable = true;
    };
}
