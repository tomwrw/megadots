{ pkgs, ... }:
{
  home.packages = [
    pkgs.proton-pass
    pkgs.proton-vpn
  ];
}
