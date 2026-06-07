# Path to where my key backup lives after LUKS decryption.
# One of the backup keys must be plugged in and mounted
# with decryption before running a deploy.
usb := "/run/media/tomwrw/SURVIVOR/keys"
# My main user for key shipping in deploy phase.
user := "tomwrw"

# Fresh install via nixos-anywhere. Stages the host and user age keys and the
# user's SSH keypair from the LUKS USB into the target's directory structure,
# then ships them with --extra-files. Ownership of the user-owned files is
# corrected on the target by tmpfiles rules and a one shot systemd activation
# script in the tomwrw module. The staging dir (private keys) is removed on exit.
deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=/tmp/megadots
    trap 'rm -rf "$staging"' EXIT
    rm -rf "$staging"
    install -Dm600 {{ usb }}/hosts/{{ HOST }}/age.txt "$staging/persist/var/lib/sops-nix/key.txt"
    install -Dm600 {{ usb }}/users/{{ user }}/age.txt "$staging/home/{{ user }}/.config/sops/age/keys.txt"
    install -Dm600 {{ usb }}/users/{{ user }}/id_ed25519 "$staging/home/{{ user }}/.ssh/id_ed25519"
    install -Dm644 {{ usb }}/users/{{ user }}/id_ed25519.pub "$staging/home/{{ user }}/.ssh/id_ed25519.pub"
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }}

build HOST:
    nixos-rebuild build --flake .#{{ HOST }}

rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host tomwrw@{{ HOST }} --sudo --ask-sudo-password
