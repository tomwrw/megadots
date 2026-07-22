cachyos-cache := "--option allow-import-from-derivation true --option extra-substituters 'https://attic.xuyh0120.win/lantian' --option extra-trusted-public-keys 'lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc='"

usb := "/run/media/tomwrw/SURVIVOR/keys"
user := "tomwrw"

deploy HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    install -Dm600 {{ usb }}/hosts/{{ HOST }}/age.txt "$staging/persist/var/lib/sops-nix/key.txt"
    for k in id_ed25519 id_ed25519_sk_primary id_ed25519_sk_backup; do
      install -Dm600 {{ usb }}/users/{{ user }}/$k "$staging/persist/home/{{ user }}/.ssh/$k"
      install -Dm644 {{ usb }}/users/{{ user }}/$k.pub "$staging/persist/home/{{ user }}/.ssh/$k.pub"
    done
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --extra-files "$staging" \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }} {{ cachyos-cache }}

build HOST:
    nixos-rebuild build --flake .#{{ HOST }} {{ cachyos-cache }}

rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host {{ user }}@{{ HOST }} --ask-sudo-password {{ cachyos-cache }}

rebuild-onhost HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --build-host {{ user }}@{{ HOST }} --target-host {{ user }}@{{ HOST }} --ask-sudo-password {{ cachyos-cache }}

local:
    sudo nixos-rebuild switch --flake .#$(hostname) {{ cachyos-cache }}

enroll-fido2 HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ HOST }}" in
      endgame) dev=/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606-part2 ;;
      flatmate) dev=/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP-part2 ;;
      *) echo "unknown host: {{ HOST }}" >&2; exit 1 ;;
    esac
    ssh -t {{ user }}@{{ HOST }} sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes "$dev"
