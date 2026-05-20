{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ente-desktop
  ];
}
