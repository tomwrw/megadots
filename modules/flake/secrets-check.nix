{ inputs, den, ... }:
let
  # Assembled from fragments rather than written whole, because this file is
  # part of the source tree the check greps. A complete literal here would
  # match itself and fail the build every time.
  #
  # The obvious alternative - grep --exclude=secrets-check.nix - puts a blind
  # spot in exactly the file someone would edit to hide a key. Splitting the
  # needles means the tracked tree never contains the thing being searched for
  # and the check needs no exclusions at all.
  needles = [
    ("AGE-SECRET" + "-KEY-1")
    ("BEGIN " + "OPENSSH PRIVATE KEY")
    ("BEGIN " + "RSA PRIVATE KEY")
    ("BEGIN " + "EC PRIVATE KEY")
    ("BEGIN " + "PGP PRIVATE KEY BLOCK")
  ];
in
{
  # The one check in this repo that uses den's own 'checks' class rather than
  # the perSystem block in checks.nix. It earns that because it is entirely
  # self-contained: it reads the source tree and nothing else, so it can't
  # re-enter the flake fixpoint the way an aspect reading
  # config.flake.nixosConfigurations would. Everything host-shaped stays in
  # checks.nix, which is the single file to read to learn what this repo
  # guarantees.
  den.aspects.checks.secrets.checks =
    { pkgs, lib, ... }:
    {
      secrets =
        let
          needleFile = pkgs.writeText "secret-needles" (lib.concatStringsSep "\n" needles);
        in
        pkgs.runCommand "check-secrets" { src = inputs.self; } ''
          cd "$src"

          # -I skips binaries so avatar.png and wallpapers aren't scanned as
          # text, -F takes the needles literally, -f reads them from the file.
          if grep -rIl -F -f ${needleFile} .; then
            echo "check-secrets: the files listed above contain plaintext key material" >&2
            exit 1
          fi

          # sops leaves its own 'sops:' metadata block on everything it
          # encrypts, so the absence of one means a file under secrets/ was
          # committed in the clear. That is the single mistake this repo cannot
          # take back, since the tree is public and history is forever.
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

  # den already routes the 'checks' class to flake.checks.<system> through
  # den.policies.checks-to-flake; this is what puts the aspect in scope for it.
  den.schema.flake-system.includes = [ den.aspects.checks.secrets ];
}
