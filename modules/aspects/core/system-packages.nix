_: {
  den.aspects.core.system-packages.nixos =
    { pkgs, ... }:
    {
      # Deliberately minimal: tools every host needs at the system level,
      # available to root and before any user's Home Manager profile exists.
      # nixfmt and fzf used to live here too, duplicating the Home Manager
      # copies in apps/shell/cli-apps.nix and apps/shell/zsh.nix; repo tooling now lives
      # in the devShell (modules/flake/devshell.nix) instead.
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
