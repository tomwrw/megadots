{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ente-auth
  ];
}
