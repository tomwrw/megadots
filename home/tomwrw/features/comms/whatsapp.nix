{ pkgs, ... }:
{
  home.packages = with pkgs; [
    karere
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/karere"
      ".local/share/karere"
    ];
  };
}
