deploy HOST:
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
      --disko-mode disko \
      --flake .#{{ HOST }} \
      --target-host nixos@{{ HOST }}

build HOST:
    nixos-rebuild build --flake .#{{ HOST }}

rebuild HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host tomwrw@{{ HOST }} --sudo --ask-sudo-password