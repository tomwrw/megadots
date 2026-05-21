{ pkgs, ... }:
{
  imports = [
    ./btop.nix
    ./ghostty.nix
    ./git.nix
    ./zsh.nix
  ];

  home.packages = [
    pkgs.bc # Arbitrary-precision calculator language.
    pkgs.bottom # Cross-platform graphical process/system monitor.
    pkgs.eza # Modern replacement for `ls`.
    pkgs.fastfetch # Highly customizable system information tool.
    pkgs.ncdu # Disk usage analyzer for the terminal.
    pkgs.nh # NixOS configuration helper and cleaner.
    pkgs.nix-diff # Tool to compare two Nix derivations.
    pkgs.nix-output-monitor # Monitors and shows build logs for Nix.
    pkgs.nixd # Nix language server.
    pkgs.nixfmt # Nix code formatter conforming to RFC 0048.
    pkgs.nvd # Nix vulnerability scanner.
  ];
}
