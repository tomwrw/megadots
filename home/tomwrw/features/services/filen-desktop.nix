{ pkgs, ... }:
{
  home.packages = [
    pkgs.filen-desktop
  ];

  # Sync state/login — path unconfirmed, verify with `ls ~/.config` after
  # first run on spectre.
  home.persistence."/persist".directories = [
    ".config/filen-desktop"
  ];
}
