{ pkgs, ... }:
{
  home.packages = [
    pkgs.joplin
    pkgs.joplin-desktop
  ];
}
