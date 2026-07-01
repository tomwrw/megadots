{ pkgs, ... }:
{
  home.packages = [
    pkgs.ryubing
    pkgs.cemu
  ];

  # Emulator config/saves — exact paths unconfirmed, verify with `ls
  # ~/.config` / `ls ~/.local/share` after first run. Game ROM/dump storage
  # is a separate, user-managed concern — make sure wherever those live is
  # covered by ~/Documents (see home/tomwrw/global/default.nix) or its own
  # explicit entry.
  home.persistence."/persist".directories = [
    ".config/Ryujinx"
    ".local/share/Cemu"
  ];
}
