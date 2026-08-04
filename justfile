usb := "/run/media/tomwrw/SURVIVOR/keys"
user := "tomwrw"

# List the available recipes.
default:
    @just --list

# Install HOST from scratch over SSH with nixos-anywhere. FORMATS ITS DISKS.
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
    # Pinned by this flake's own lock - see modules/flake/deploy.nix.
    nix run .#nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }}

# Build HOST's closure locally, no activation.
build HOST:
    nixos-rebuild build --flake .#{{ HOST }}

# Switch HOST to a locally-built closure over SSH.
rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host {{ user }}@{{ HOST }} --sudo --ask-sudo-password

# Build HOST locally and show what would change versus the running system.
diff HOST: (build HOST)
    nvd diff /run/current-system result

# Read from the config that actually opens it at boot rather than rebuilt from
# the disk id, so it survives repartitioning - the old version appended
# "-part2" and would have pointed at the ESP if partition order ever changed.

# Print the LUKS device path for HOST.
luks-device HOST:
    @nix eval --raw .#nixosConfigurations.{{ HOST }}.config.boot.initrd.luks.devices.crypted.device

# Add the inserted FIDO2 token as a LUKS keyslot on HOST.
enroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    dev="$(just luks-device {{ HOST }})"
    ssh -t {{ user }}@{{ HOST }} sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes "$dev"

# Remove all FIDO2 keyslots from HOST, leaving the passphrase.
unenroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    dev="$(just luks-device {{ HOST }})"
    if [[ "{{ HOST }}" == "$(hostname)" ]]; then
      sudo cryptsetup open --test-passphrase "$dev" && sudo systemd-cryptenroll --wipe-slot=fido2 "$dev"
    else
      ssh -t {{ user }}@{{ HOST }} "sudo cryptsetup open --test-passphrase '$dev' && sudo systemd-cryptenroll --wipe-slot=fido2 '$dev'"
    fi

# Format the tree (nixfmt + deadnix + statix via treefmt).
fmt:
    nix fmt

# Build both hosts, the fleet invariants and the roster checks.
check:
    nix flake check

# Update all flake inputs.
update:
    nix flake update

# Matches the 30-day window core/nix.nix already applies weekly.

# Collect garbage on the local machine.
gc:
    nix-collect-garbage --delete-older-than 30d
    sudo nix-collect-garbage --delete-older-than 30d

# Edit an encrypted secrets file in place, e.g. `just secrets-edit secrets/users/tomwrw.yaml`.
secrets-edit FILE:
    sops {{ FILE }}

# Left interactive (no -y) deliberately - this is exactly the moment to eyeball
# the per-recipient diff sops prints before re-encrypting.

# Re-sync sops recipients on every secrets file against .sops.yaml.
secrets-updatekeys:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in secrets/hosts/*.yaml secrets/users/*.yaml; do
      sops updatekeys "$f"
    done
