_: {
  megadots.apps.shell.cli-apps.description =
    "A set of command-line tools that replace or supplement the coreutils defaults.";

  megadots.apps.shell.cli-apps.homeManager =
    { pkgs, ... }:
    {
      # eza and nh go through their Home Manager modules and not home.packages.
      # programs.eza sets up the ls aliases, see apps/shell/zsh.nix, and
      # programs.nh carries the flake and config plumbing.
      #
      # nh.clean stays off. core/nix.nix already runs nix.gc weekly, and two
      # garbage collectors with different retention on one store is how I lose
      # the generation I wanted.
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
