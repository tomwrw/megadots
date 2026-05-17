{ inputs, ... }:
{
  # This overlay provides a convenient way to access the packages from all
  # flake inputs. For each input, it creates an attribute set under `pkgs.inputs`
  # (e.g., `pkgs.inputs.spicetify-nix`). This makes it easy to use packages
  # from other flakes in your configuration without having to manually dig
  # through `inputs`. It intelligently looks for `packages` or `legacyPackages`
  # on the flake for the current system.
  flake-inputs =
    final: _:
    let
      hostSystem = final.stdenv.hostPlatform.system;
    in
    {
      inputs = builtins.mapAttrs (
        _: flake:
        let
          # Use the new path for attribute lookups
          legacyPackages = (flake.legacyPackages or { }).${hostSystem} or { };
          packages = (flake.packages or { }).${hostSystem} or { };
        in
        if legacyPackages != { } then legacyPackages else packages
      ) inputs;
    };

  # This overlay adds `pkgs.stable` which points to the `nixpkgs-stable`
  # flake input. This allows you to install packages from the stable
  # channel on a system that primarily uses `nixpkgs-unstable`. You can
  # install a stable package with `pkgs.stable.package-name`.
  stable = final: _: {
    stable = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system};
  };
}
