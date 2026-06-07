{ ... }:
{
  den.aspects.system-packages.nixos =
    { pkgs, ... }:
    {
      # General CLI tooling installed on every NixOS host.
      environment.systemPackages = [
        pkgs.age
        pkgs.nixfmt
        pkgs.fd
        pkgs.fzf
        pkgs.jq
        pkgs.just
        pkgs.pciutils
        pkgs.ripgrep
        pkgs.sbctl
        pkgs.ssh-to-age
        pkgs.sops
        pkgs.unzip
      ];
    };
}
