_: {
  den.aspects.core.system-packages.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.age
        pkgs.nixfmt
        pkgs.fd
        pkgs.fzf
        pkgs.jq
        pkgs.just
        pkgs.pciutils
        pkgs.ripgrep
        pkgs.ssh-to-age
        pkgs.sops
        pkgs.unzip
      ];
    };
}
