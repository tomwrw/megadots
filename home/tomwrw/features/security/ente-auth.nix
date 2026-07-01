{ pkgs, ... }:
{
  home.packages = [
    pkgs.ente-auth
  ];

  # TOTP secrets — highest blast-radius item in the persistence inventory if
  # missed. Path unconfirmed — verify with `ls ~/.config` after first run on
  # spectre before trusting it.
  home.persistence."/persist".directories = [
    ".config/ente-auth"
  ];
}
