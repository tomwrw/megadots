{ pkgs, ... }:
{
  home.packages = [
    pkgs.claude-code
    pkgs.claude-monitor
  ];
}
