_: {
  # Exposed so the justfile can call `nix run .#nixos-anywhere` instead of
  # `nix run github:nix-community/nixos-anywhere`, which resolved at HEAD on
  # every invocation. Deploying is the one step that formats disks, so it
  # should be the least improvised thing here - this pins it to the same
  # nixpkgs as everything else, recorded in flake.lock.
  perSystem =
    { pkgs, ... }:
    {
      packages.nixos-anywhere = pkgs.nixos-anywhere;
    };
}
