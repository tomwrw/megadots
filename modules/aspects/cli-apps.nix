{ ... }:
{
  # General CLI tooling for tomwrw (Home Manager), on every host.
  den.aspects.cli-apps.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.bc # arbitrary-precision calculator
        pkgs.bottom # graphical process/system monitor
        pkgs.eza # modern `ls`
        pkgs.fastfetch # system info
        pkgs.ncdu # disk usage analyzer
        pkgs.nh # NixOS helper/cleaner
        pkgs.nix-diff # compare derivations
        pkgs.nix-output-monitor # nicer build logs
        pkgs.nixd # Nix language server
        pkgs.nixfmt # Nix formatter
        pkgs.nvd # Nix version diff
      ];
    };
}
