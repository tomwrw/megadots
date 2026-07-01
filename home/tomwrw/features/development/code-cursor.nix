{ pkgs, ... }:
{
  home.packages = [
    pkgs.code-cursor
  ];

  home.persistence."/persist".directories = [
    ".config/Cursor"
  ];
}
