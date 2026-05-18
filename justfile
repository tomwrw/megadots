cachyos-cache := "--option extra-substituters 'https://attic.xuyh0120.win/lantian' --option extra-trusted-public-keys 'lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc='"

# Phase 1 — install OS. Nothing ships from the repo; nixos-anywhere
# prompts for the LUKS passphrase interactively (type from password
# manager). Secrets will NOT work until `just bootstrap HOST` runs.
deploy HOST:
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }} {{ cachyos-cache }}

# Phase 2 — register the host's age identity (derived from its
# auto-generated SSH host key), place the user SSH key, rewrap
# secrets, trigger rebuild. After this, all secrets work.
bootstrap HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    # Ensure the user's age key exists locally. Deterministically derived
    # from ~/.ssh/id_ed25519, so it always matches the &tomwrw recipient
    # in .sops.yaml (as long as that recipient was registered from the
    # same SSH key). Prompts for the SSH passphrase exactly once, when
    # the file is first created.
    if [ ! -f ~/.config/sops/age/keys.txt ]; then
      echo "Deriving user age key from ~/.ssh/id_ed25519..."
      mkdir -p ~/.config/sops/age
      ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt
      chmod 600 ~/.config/sops/age/keys.txt
      echo "Created ~/.config/sops/age/keys.txt with pubkey:"
      age-keygen -y ~/.config/sops/age/keys.txt
      echo "Confirm this matches &tomwrw in .sops.yaml."
    fi
    AGE_PUB=$(ssh tomwrw@{{ HOST }} 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age)
    echo "{{ HOST }} age pubkey: $AGE_PUB"
    if grep -q "&{{ HOST }} " .sops.yaml; then
      # \& in the replacement is a literal & (unescaped & means "the match").
      sed -i "s|&{{ HOST }} age[^ ]*|\&{{ HOST }} $AGE_PUB|" .sops.yaml
    else
      echo "ERROR: &{{ HOST }} not found in .sops.yaml."
      echo "Add it to the keys: list and to the creation_rules age list, then re-run."
      exit 1
    fi
    sops updatekeys -y secrets/secrets.yaml
    # Write secrets to /persist so they survive root rollback and aren't
    # masked by impermanence bindmounts. Pre-create the persist dirs with
    # sudo because they may not exist yet on first bootstrap (the
    # impermanence module creates them on next activation, which is too
    # late for the scp below).
    ssh tomwrw@{{ HOST }} 'sudo install -d -o tomwrw -g users -m 700 /persist/home/tomwrw/.config/sops/age /persist/home/tomwrw/.ssh'
    scp ~/.config/sops/age/keys.txt tomwrw@{{ HOST }}:/persist/home/tomwrw/.config/sops/age/keys.txt
    scp ~/.ssh/id_ed25519           tomwrw@{{ HOST }}:/persist/home/tomwrw/.ssh/id_ed25519
    scp ~/.ssh/id_ed25519.pub       tomwrw@{{ HOST }}:/persist/home/tomwrw/.ssh/id_ed25519.pub
    ssh tomwrw@{{ HOST }} 'chmod 600 /persist/home/tomwrw/.config/sops/age/keys.txt /persist/home/tomwrw/.ssh/id_ed25519 && chmod 644 /persist/home/tomwrw/.ssh/id_ed25519.pub'
    nixos-rebuild switch --flake .#{{ HOST }} --target-host tomwrw@{{ HOST }} --sudo {{ cachyos-cache }}

# Build a host's config locally (no activation).
build HOST:
    nixos-rebuild build --flake .#{{ HOST }} {{ cachyos-cache }}

# Rebuild a remote host.
rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host tomwrw@{{ HOST }} --sudo {{ cachyos-cache }}

# Rebuild the local host.
local:
    sudo nixos-rebuild switch --flake .#$(hostname) {{ cachyos-cache }}
