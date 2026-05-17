{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ente-auth
  ];

  home.persistence."/persist" = {
    directories = [
      ".local/share/io.ente.auth"
    ];
  };
}
