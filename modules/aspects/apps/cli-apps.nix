_: {
  den.aspects.apps.shell.cli-apps.homeManager =
    { pkgs, ... }:
    {
      # eza and nh go through their Home Manager modules rather than
      # home.packages: programs.eza wires up the ls aliases (see apps/zsh.nix,
      # which no longer hand-rolls them) and programs.nh carries the
      # flake/config plumbing.
      #
      # nh.clean is deliberately NOT enabled - core/nix.nix already runs nix.gc
      # weekly, and two garbage collectors with different retention on one
      # store is how you lose the generation you wanted.
      programs.eza.enable = true;
      programs.nh.enable = true;

      home.packages = [
        pkgs.bc # arbitrary-precision calculator
        pkgs.fastfetch # system info
        pkgs.ncdu # disk usage analyzer
        pkgs.nix-diff # compare derivations
        pkgs.nix-output-monitor # nicer build logs
        pkgs.nixd # Nix language server
        pkgs.nixfmt # Nix formatter
        pkgs.nvd # Nix version diff
      ];
    };
}
