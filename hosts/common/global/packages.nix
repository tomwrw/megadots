{ pkgs, ... }:
{
  # Packages installed on all hosts go here.
  environment.systemPackages = [
    pkgs.age
    pkgs.fd
    pkgs.fzf
    pkgs.jq
    pkgs.just
    pkgs.nixfmt
    pkgs.pciutils
    pkgs.ripgrep
    pkgs.sbctl
    pkgs.sops
    pkgs.ssh-to-age
    pkgs.unzip
  ];
}
