{ pkgs, ... }:
{
  # Packages installed on all hosts go here.
  environment.systemPackages = with pkgs; [
    age
    nixfmt
    fd
    fzf
    jq
    just
    pciutils
    ripgrep
    sbctl
    ssh-to-age
    sops
    unzip
  ];
}
