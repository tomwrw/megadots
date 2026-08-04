_: {
  # Everything the justfile recipes shell out to, so a contributor (or a fresh
  # machine that has not been deployed yet) can run them without these tools
  # being installed system-wide. 'nix develop' is the supported entry point;
  # core/system-packages.nix deliberately only carries what MY hosts need at
  # runtime, not what building this repo needs.
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          age
          just
          nixfmt
          nixos-anywhere
          nvd
          sops
          ssh-to-age
        ];
      };
    };
}
