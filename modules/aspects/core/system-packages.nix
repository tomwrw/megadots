_: {
  den.aspects.core.system-packages.nixos =
    { pkgs, ... }:
    {
      # Kept small. Just what every host needs at system level, available to
      # root and before Home Manager exists. Tooling for working on this repo
      # lives in the devShell instead.
      environment.systemPackages = [
        pkgs.age
        pkgs.fd
        pkgs.jq
        pkgs.just
        pkgs.pciutils
        pkgs.ripgrep
        pkgs.sops
        pkgs.unzip
      ];
    };
}
