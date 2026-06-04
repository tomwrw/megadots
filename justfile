# Path to the (mounted, LUKS-decrypted) USB key tree holding the age + SSH keys.
usb := "/run/media/tomwrw/SURVIVOR/keys"
# User whose keys are shipped during deploy (both hosts currently have tomwrw).
user := "tomwrw"

# Fresh install via nixos-anywhere. Stages the host + user age keys and the
# user's SSH keypair from the LUKS USB into the target's directory structure,
# then ships them with --extra-files. Ownership of the user-owned files is
# corrected on the target by tmpfiles rules in the tomwrw module. The staging
# dir (private keys) is removed on exit.
deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=/tmp/megadots
    trap 'rm -rf "$staging"' EXIT
    rm -rf "$staging"
    install -Dm600 {{ usb }}/hosts/{{ HOST }}/age.txt         "$staging/persist/var/lib/sops-nix/key.txt"
    install -Dm600 {{ usb }}/users/{{ user }}/age.txt         "$staging/home/{{ user }}/.config/sops/age/keys.txt"
    install -Dm600 {{ usb }}/users/{{ user }}/id_ed25519      "$staging/home/{{ user }}/.ssh/id_ed25519"
    install -Dm644 {{ usb }}/users/{{ user }}/id_ed25519.pub  "$staging/home/{{ user }}/.ssh/id_ed25519.pub"
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }}

build HOST:
    nixos-rebuild build --flake .#{{ HOST }}

rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host tomwrw@{{ HOST }} --sudo --ask-sudo-password
