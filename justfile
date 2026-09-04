cachyos-cache := "--option allow-import-from-derivation true --option extra-substituters 'https://nyx-cache.chaotic.cx/' --option extra-trusted-public-keys 'nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk='"
usb := "/run/media/tomwrw/SURVIVOR/keys"
user := "tomwrw"

# List the available recipes.
default:
    @just --list

# Install HOST from scratch over SSH with nixos-anywhere. FORMATS ITS DISKS.
# The USB mirrors the destination, so there is no manifest and no mapping:
#
#   <usb>/hosts/<host>/age.txt     -> /persist/var/lib/sops-nix/key.txt
#   <usb>/users/<user>/**          -> /persist/home/<user>/**
#
# Everything lands under /persist and not /home, because / (and so /home) goes
# back to a blank snapshot every boot; impermanence bind mounts it into the
# live home. Whatever a user needs, put it on the USB at the path it should
# have in their home - .ssh/id_ed25519, .config/sops/age/keys.txt - and it
# arrives there. Adding a key is a copy on the USB and nothing in this repo.
#
# This replaced a 'seed' quirk, a host-scope consumer aspect that derived
# tmpfiles ownership and a chown unit, a machine-readable option, a recipe to
# read it and four invariants to police it - all of which existed because
# --extra-files copies as root. --chown does that job during the install
# instead of on every boot, which is where it belonged.

# Install HOST from scratch over SSH with nixos-anywhere. FORMATS ITS DISKS.
deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    install -Dm600 {{ usb }}/hosts/{{ HOST }}/age.txt "$staging/persist/var/lib/sops-nix/key.txt"
    # -a keeps the modes off the USB, so a 0600 private key stays 0600 and
    # sshd/sops do not refuse it. Check them there, not here.
    for u in {{ usb }}/users/*/; do
      [[ -d "$u" ]] || continue
      install -d "$staging/persist/home/$(basename "$u")"
      cp -a "$u." "$staging/persist/home/$(basename "$u")/"
    done
    # uid:gid rather than names: this runs against the installer image, which
    # has no account for my user. 1000:100 is the first normal user and the
    # 'users' group, which is what den.batteries.primary-user creates.
    chown_args=()
    for u in {{ usb }}/users/*/; do
      [[ -d "$u" ]] || continue
      chown_args+=(--chown "/persist/home/$(basename "$u")" 1000:100)
    done
    # Pinned by this flake's own lock - see modules/flake/deploy.nix.
    nix run .#nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      "${chown_args[@]}" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }}

# Build HOST's closure locally, no activation.
build HOST:
    nixos-rebuild build --flake .#{{ HOST }} {{ cachyos-cache }}

# Switch HOST to a locally-built closure over SSH.
rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host {{ user }}@{{ HOST }} --sudo --ask-sudo-password

# Build HOST locally and show what would change versus the running system.
diff HOST: (build HOST)
    nvd diff /run/current-system result

# Read from the config that actually opens it at boot instead of rebuilding it
# from the disk id, so it survives repartitioning. The old version appended
# "-part2" and would have pointed at the ESP if the partition order changed.

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

# Builds both hosts, then runs the secrets scan, treefmt and flake-file. No
# list to keep in step - it takes whatever the flake exposes as checks.

# Run every check.
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

# Edit an encrypted secrets file in place, e.g. 'just secrets-edit secrets/users/tomwrw.yaml'.
secrets-edit FILE:
    sops {{ FILE }}

# Left interactive on purpose. This is exactly the moment to look at the
# per-recipient diff sops prints before it re-encrypts anything.

# Re-sync sops recipients on every secrets file against .sops.yaml.
secrets-updatekeys:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in secrets/hosts/*.yaml secrets/users/*.yaml; do
      sops updatekeys "$f"
    done
