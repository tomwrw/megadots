{ pkgs, ... }:
{
  imports = [
    ./btop.nix
    ./ghostty.nix
    ./git.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    bc # Arbitrary-precision calculator language.
    bottom # Cross-platform graphical process/system monitor.
    eza # Modern replacement for `ls`.
    fastfetch # Highly customizable system information tool.
    ncdu # Disk usage analyzer for the terminal.
    nh # NixOS configuration helper and cleaner.
    nix-diff # Tool to compare two Nix derivations.
    nix-output-monitor # Monitors and shows build logs for Nix.
    nixd # Nix language server.
    nixfmt # Nix code formatter conforming to RFC 0048.
    nvd # Nix vulnerability scanner.
  ];
}
