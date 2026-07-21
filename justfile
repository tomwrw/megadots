cachyos-cache := "--option allow-import-from-derivation true --option extra-substituters 'https://attic.xuyh0120.win/lantian' --option extra-trusted-public-keys 'lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc='"

usb := "/run/media/tomwrw/SURVIVOR/keys"
user := "tomwrw"

# nixos-rebuild opens several SSH connections per run. Multiplexing them over
# one master means a resident FIDO2 sk credential costs a single touch + PIN
# for the whole rebuild rather than one per connection.
ssh-opts := "-A -o ControlMaster=auto -o ControlPath=/tmp/nixos-rebuild-%r@%h:%p -o ControlPersist=5m"

# Install OS and seed the host's age key + FIDO2 sk key handles from the
# USB stick via --extra-files. Secrets and SSH/git signing work immediately
# after first boot — no separate bootstrap phase needed.
deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    install -Dm600 {{ usb }}/hosts/{{ HOST }}/age.txt "$staging/persist/var/lib/sops-nix/key.txt"
    # FIDO2 sk key handles (useless without the physical token); seeding
    # them avoids a post-deploy `ssh-keygen -K`.
    for k in id_ed25519 id_ed25519_sk_primary id_ed25519_sk_backup; do
      install -Dm600 {{ usb }}/users/{{ user }}/$k "$staging/persist/home/{{ user }}/.ssh/$k"
      install -Dm644 {{ usb }}/users/{{ user }}/$k.pub "$staging/persist/home/{{ user }}/.ssh/$k.pub"
    done
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }} {{ cachyos-cache }}

# Build a host's config locally (no activation).
build HOST:
    nixos-rebuild build --flake .#{{ HOST }} {{ cachyos-cache }}

# Rebuild a remote host. authorizedKeys accepts both the resident FIDO2 sk
# credentials and the non-resident id_ed25519, so this runs unattended off
# the latter. If you authenticate with an sk key instead, ControlMaster
# below keeps it to a single touch + PIN for the whole run.
#
# --ask-sudo-password: hosts keep security.sudo.wheelNeedsPassword = true, and
# the activation runs over a non-interactive ssh channel with no TTY for sudo
# to prompt on, so nixos-rebuild has to collect the password locally instead.
rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host {{ user }}@{{ HOST }} --ask-sudo-password {{ cachyos-cache }}

# One-time bridge: build on the target instead of pushing a closure.
# Use this when the target's nix daemon hasn't yet learned to trust
# {{ user }} (e.g. on a freshly deployed host, before the user module's
# nix.settings.trusted-users entry has been activated). After one
# successful run, `just rebuild HOST` works normally.
rebuild-onhost HOST:
    NIX_SSHOPTS="{{ ssh-opts }}" nixos-rebuild switch --flake .#{{ HOST }} --build-host {{ user }}@{{ HOST }} --target-host {{ user }}@{{ HOST }} --ask-sudo-password {{ cachyos-cache }}

# Rebuild the local host.
local:
    sudo nixos-rebuild switch --flake .#$(hostname) {{ cachyos-cache }}

# Enroll the FIDO2 key currently plugged into HOST in its LUKS header.
# Run once per token; the passphrase slot remains as fallback.
enroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ HOST }}" in
      endgame) dev=/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606-part2 ;;
      flatmate) dev=/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP-part2 ;;
      *) echo "unknown host: {{ HOST }}" >&2; exit 1 ;;
    esac
    ssh -t {{ user }}@{{ HOST }} sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes "$dev"
