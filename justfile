cachyos-cache := "--option extra-substituters 'https://attic.xuyh0120.win/lantian' --option extra-trusted-public-keys 'lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc='"

# Decrypt the committed host age key + LUKS passphrase for a nixos-anywhere deploy.
prep HOST:
    rm -rf /tmp/extra-files /tmp/luks-password
    mkdir -p /tmp/extra-files/persist/var/lib/sops-nix
    age -d -i ~/.config/sops/age/keys.txt keys/{{ HOST }}.enc > /tmp/extra-files/persist/var/lib/sops-nix/key.txt
    chmod 600 /tmp/extra-files/persist/var/lib/sops-nix/key.txt
    sops -d --extract '["luks-passphrase"]' secrets/{{ HOST }}.yaml > /tmp/luks-password
    chmod 600 /tmp/luks-password

# Deploy (remote, wipes target).
spectre-deploy: (prep "spectre")
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- --disko-mode disko --extra-files /tmp/extra-files --disk-encryption-keys /tmp/luks-password /tmp/luks-password --flake .#spectre --target-host nixos@spectre {{ cachyos-cache }}

endgame-deploy: (prep "endgame")
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- --disko-mode disko --extra-files /tmp/extra-files --disk-encryption-keys /tmp/luks-password /tmp/luks-password --flake .#endgame --target-host nixos@endgame {{ cachyos-cache }}

flatmate-deploy: (prep "flatmate")
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- --disko-mode disko --extra-files /tmp/extra-files --disk-encryption-keys /tmp/luks-password /tmp/luks-password --flake .#flatmate --target-host nixos@flatmate {{ cachyos-cache }}

# Build (local, no switch).
spectre-build:
    nixos-rebuild build --flake .#spectre {{ cachyos-cache }}

endgame-build:
    nixos-rebuild build --flake .#endgame {{ cachyos-cache }}

flatmate-build:
    nixos-rebuild build --flake .#flatmate {{ cachyos-cache }}

# Rebuild local (run on the host itself).
local-rebuild:
    sudo nixos-rebuild switch --flake .#$(hostname) {{ cachyos-cache }}

# Rebuild remote.
spectre-rebuild:
    nixos-rebuild switch --flake .#spectre --target-host tomwrw@spectre --ask-sudo-password {{ cachyos-cache }}

endgame-rebuild:
    nixos-rebuild switch --flake .#endgame --target-host tomwrw@endgame --ask-sudo-password {{ cachyos-cache }}

flatmate-rebuild:
    nixos-rebuild switch --flake .#flatmate --target-host tomwrw@flatmate --ask-sudo-password {{ cachyos-cache }}
