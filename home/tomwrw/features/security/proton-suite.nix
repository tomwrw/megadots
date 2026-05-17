{ pkgs, ... }:
{
  home.packages = with pkgs; [
    proton-pass
    proton-vpn
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/Proton"
    ];
  };
}
