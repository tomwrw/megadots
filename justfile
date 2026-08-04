usb := "/run/media/tomwrw/SURVIVOR/keys"
user := "tomwrw"

deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    install -Dm600 {{ usb }}/hosts/{{ HOST }}/age.txt "$staging/persist/var/lib/sops-nix/key.txt"
    install -Dm600 {{ usb }}/users/{{ user }}/age.txt "$staging/home/{{ user }}/.config/sops/age/keys.txt"
    # FIDO2 sk key handles (useless without the physical token); seeding them
    # avoids a post-deploy `ssh-keygen -K`.
    for k in id_ed25519 id_ed25519_sk_primary id_ed25519_sk_backup; do
      install -Dm600 {{ usb }}/users/{{ user }}/$k "$staging/home/{{ user }}/.ssh/$k"
      install -Dm644 {{ usb }}/users/{{ user }}/$k.pub "$staging/home/{{ user }}/.ssh/$k.pub"
    done
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }}

build HOST:
    nixos-rebuild build --flake .#{{ HOST }}

rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host {{ user }}@{{ HOST }} --sudo --ask-sudo-password

# The LUKS-partition device path for HOST, read from the den host roster
# (single source of truth: modules/den/hosts.nix) rather than hardcoded here.
luks-part HOST:
    @nix eval --raw .#den.hosts.x86_64-linux.{{ HOST }}.disk.id | sed 's/$/-part2/'

enroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    dev="$(just luks-part {{ HOST }})"
    ssh -t {{ user }}@{{ HOST }} sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes "$dev"

unenroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    dev="$(just luks-part {{ HOST }})"
    if [[ "{{ HOST }}" == "$(hostname)" ]]; then
      sudo cryptsetup open --test-passphrase "$dev" && sudo systemd-cryptenroll --wipe-slot=fido2 "$dev"
    else
      ssh -t {{ user }}@{{ HOST }} "sudo cryptsetup open --test-passphrase '$dev' && sudo systemd-cryptenroll --wipe-slot=fido2 '$dev'"
    fi

# Re-sync sops recipients on every secrets file against .sops.yaml
# (e.g. after rotating fido2-primary/fido2-backup). Left interactive
# (no -y) deliberately - this is exactly the moment to eyeball the
# per-recipient diff sops prints before re-encrypting.
secrets-updatekeys:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in secrets/hosts/*.yaml secrets/users/*.yaml; do
      sops updatekeys "$f"
    done
