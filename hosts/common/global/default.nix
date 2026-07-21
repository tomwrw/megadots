{ outputs, ... }:
{
  imports = [
    ./boot.nix
    ./fonts.nix
    ./gnupg.nix
    ./hardening.nix
    ./hardware.nix
    ./home-manager.nix
    ./impermanence.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./sops.nix
    ./ssh.nix
    ./systemd-initrd.nix
    ./zsh.nix
  ]
  # Include any custom NixOS modules I have defined.
  ++ (builtins.attrValues outputs.nixosModules);
}
