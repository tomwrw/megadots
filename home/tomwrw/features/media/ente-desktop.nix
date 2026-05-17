{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ente-desktop
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/ente"
    ];
  };
}
