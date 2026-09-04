{
  config,
  inputs,
  lib,
  ...
}:
let
  # Assembled from fragments rather than written whole, because this file is
  # part of the source tree the check greps: a complete literal would match
  # itself. Splitting them beats grep --exclude, which would put a blind spot in
  # exactly the file someone would edit to hide a key.
  needles = [
    ("AGE-SECRET" + "-KEY-1")
    ("BEGIN " + "OPENSSH PRIVATE KEY")
    ("BEGIN " + "RSA PRIVATE KEY")
    ("BEGIN " + "EC PRIVATE KEY")
    ("BEGIN " + "PGP PRIVATE KEY BLOCK")
  ];
in
{
  # Two checks, and treefmt and flake-file add their own.
  #
  # Building every host is the one that matters: it catches anything that has
  # stopped evaluating or building. There are no invariants here - a broken one
  # shows up when the machine boots, and deploys are atomic.
  perSystem =
    { pkgs, system, ... }:
    {
      checks =
        lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel) (
          lib.filterAttrs (
            _: nixos: nixos.pkgs.stdenv.hostPlatform.system == system
          ) config.flake.nixosConfigurations
        )
        // {
          # The one mistake a public repo cannot take back.
          secrets =
            let
              needleFile = pkgs.writeText "secret-needles" (lib.concatStringsSep "\n" needles);
            in
            pkgs.runCommand "check-secrets" { src = inputs.self; } ''
              cd "$src"

              # -I skips binaries so the wallpapers aren't scanned as text, -F
              # takes the needles literally, -f reads them from the file.
              if grep -rIl -F -f ${needleFile} .; then
                echo "check-secrets: the files listed above contain plaintext key material" >&2
                exit 1
              fi

              # sops leaves a 'sops:' metadata block on everything it encrypts,
              # so the absence of one means a file under secrets/ was committed
              # in the clear.
              shopt -s nullglob
              files=(secrets/hosts/*.yaml secrets/users/*.yaml)
              if [ ''${#files[@]} -eq 0 ]; then
                echo "check-secrets: found no files under secrets/ - has the layout moved?" >&2
                exit 1
              fi
              for f in "''${files[@]}"; do
                if ! grep -q '^sops:' "$f"; then
                  echo "check-secrets: $f is not sops-encrypted" >&2
                  exit 1
                fi
              done

              touch "$out"
            '';
        };
    };
}
