{ outputs, ... }:
{
  imports = [
    ./fonts.nix
    ./gnupg.nix
    ./hardware.nix
    ./home-manager.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./packages.nix
    ./preservation.nix
    ./security.nix
    ./sops.nix
    ./ssh.nix
    ./systemd-initrd.nix
    ./yubikey.nix
    ./zsh.nix
  ]
  # Include any custom NixOS modules I have defined.
  ++ (builtins.attrValues outputs.nixosModules);
}
