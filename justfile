usb := "/run/media/tomwrw/SURVIVOR/keys"
user := "tomwrw"

deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
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
