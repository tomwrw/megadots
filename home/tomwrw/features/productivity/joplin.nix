{ pkgs, ... }:
{
  home.packages = [
    pkgs.joplin
    pkgs.joplin-desktop
  ];

  # Notebooks/sync state — path unconfirmed, verify with `ls ~/.config`
  # after first run on spectre.
  home.persistence."/persist".directories = [
    ".config/joplin-desktop"
  ];
}
