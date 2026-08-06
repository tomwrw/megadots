_: {
  # Everything my justfile recipes shell out to, so I can run them on a
  # machine I haven't deployed yet. 'nix develop' is the way in.
  # core/system-packages.nix only carries what my hosts need at runtime, not
  # what working on this repo needs.
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
