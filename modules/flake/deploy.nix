_: {
  # Exposed so my justfile can run 'nix run .#nixos-anywhere' instead of
  # pulling github:nix-community/nixos-anywhere at HEAD every time. Deploying
  # is the one thing that formats disks, so it should be the least improvised
  # step I have. This pins it to the same nixpkgs as everything else.
  perSystem =
    { pkgs, ... }:
    {
      packages.nixos-anywhere = pkgs.nixos-anywhere;
    };
}
