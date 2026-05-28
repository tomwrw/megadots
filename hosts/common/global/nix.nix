{
  inputs,
  lib,
  outputs,
  ...
}:
{
  # Nixpkgs config for all my hosts.
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };
  # General nix config for all my hosts.
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake.
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    # Add custom caches here.
    settings = {
      extra-substituters = [
        "https://chaotic-nyx.cachix.org/"
        "https://cosmic.cachix.org/"
        "https://niri.cachix.org/"
      ];
      extra-trusted-public-keys = [
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
      # See https://jackson.dev/post/nix-reasonable-defaults/ for
      # explaination of sensible defaults.
      connect-timeout = 5;
      log-lines = 25;
      # Add the root user and wheel group as trusted.
      trusted-users = [
        "root"
      ];
      # Deduplicate and optimise nix store.
      auto-optimise-store = true;
      # Stop telling me there are uncommited changes!
      warn-dirty = false;
      # Allow importing derivations from derivations.
      allow-import-from-derivation = false;
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
  # nix-ld provides a shim for ELF binaries to automatically find their
  # shared library dependencies in the Nix store. This is essential for
  # running pre-compiled binaries that are not packaged in Nixpkgs.
  programs.nix-ld = {
    enable = true;
  };
}
