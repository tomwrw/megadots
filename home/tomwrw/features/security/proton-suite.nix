{ pkgs, ... }:
{
  home.packages = [
    pkgs.proton-pass
    pkgs.proton-vpn
  ];

  # Session/login state for both apps — paths unconfirmed, verify with
  # `ls ~/.config` after first run on spectre.
  home.persistence."/persist".directories = [
    ".config/Proton Pass"
    ".config/ProtonVPN"
  ];
}
