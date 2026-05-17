{ pkgs, ... }:
{
  home.packages = with pkgs; [
    filen-desktop
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/@filen"
    ];
  };
}
