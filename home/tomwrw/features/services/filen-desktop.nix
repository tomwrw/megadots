{ pkgs, ... }:
{
  home.packages = [
    pkgs.filen-desktop
  ];

  home.persistence."/persist".directories = [
    ".config/@filen"
  ];
}
