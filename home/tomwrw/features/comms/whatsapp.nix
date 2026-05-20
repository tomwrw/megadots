{ pkgs, ... }:
{
  home.packages = with pkgs; [
    karere
  ];
}
