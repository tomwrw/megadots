{ inputs, ... }:
{
  den.aspects.core.nix.nixos =
    { lib, ... }:
    {
      nix = {
        # Make 'nix run nixpkgs#…' etc. resolve to the same nixpkgs this system
        # was built from (pinned, consistent nix3 commands).
        #
        # Deliberately ONLY nixpkgs. Mapping every input pins each one's source
        # into the system closure, which is then pushed in full on every
        # 'nixos-rebuild --target-host' deploy and retained against the GC's
        # 30-day window - several hundred MB to register flake refs nobody
        # types. Add a second entry here only when you actually want it.
        registry.nixpkgs.flake = inputs.nixpkgs;

        settings = {
          # See https://jackson.dev/post/nix-reasonable-defaults/ for
          # explanation of sensible defaults.
          connect-timeout = 5;
          log-lines = 25;
          # Trust the wheel group so 'nixos-rebuild --target-host' can push
          # locally-built closures to the fleet (single-admin LAN).
          trusted-users = [
            "root"
            "@wheel"
          ];
          # Hard-links identical store paths on every write, rather than
          # out-of-band via nix.optimise. Costs a little latency per build in
          # exchange for never needing to remember to run it.
          auto-optimise-store = true;

          # Import-from-derivation must stay enabled: stylix's base16 scheme
          # reader readFiles a yaml from the base16-schemes derivation at eval
          # time, which is IFD. (Was the den default; do not disable.)
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

          # Free space automatically mid-build once under 512MB, up to 1GB.
          # mkDefault so a host with a small disk can lower them.
          min-free = lib.mkDefault 536870912;
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
