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

enroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ HOST }}" in
      endgame) dev=/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606-part2 ;;
      flatmate) dev=/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP-part2 ;;
      *) echo "unknown host: {{ HOST }}" >&2; exit 1 ;;
    esac
    ssh -t {{ user }}@{{ HOST }} sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes "$dev"

unenroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ HOST }}" in
      endgame) dev=/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606-part2 ;;
      flatmate) dev=/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP-part2 ;;
      *) echo "unknown host: {{ HOST }}" >&2; exit 1 ;;
    esac
    if [[ "{{ HOST }}" == "$(hostname)" ]]; then
      sudo cryptsetup open --test-passphrase "$dev" && sudo systemd-cryptenroll --wipe-slot=fido2 "$dev"
    else
      ssh -t {{ user }}@{{ HOST }} "sudo cryptsetup open --test-passphrase '$dev' && sudo systemd-cryptenroll --wipe-slot=fido2 '$dev'"
    fi
