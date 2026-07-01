{ pkgs, ... }:
{
  home.packages = [
    pkgs.karere
  ];

  # Karere's actual data dir is unconfirmed — verify with `ls ~/.local/share`
  # / `ls ~/.config` after first run on spectre before trusting this path.
  home.persistence."/persist".directories = [
    ".local/share/karere"
  ];
}
