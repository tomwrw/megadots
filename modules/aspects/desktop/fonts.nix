_: {
  # The system font set: what is available to pick from, rather than what the
  # desktop actually uses. The themed families are named in desktop/stylix.nix,
  # and Stylix installs whatever it names itself - so removing something here
  # does not take it out of the theme.
  den.aspects.fonts.nixos =
    { pkgs, ... }:
    {
      fonts.packages = [
        # GNOME's own families, and what stylix themes with. The GNOME module
        # installs this too; named here so a host without GNOME still has them.
        pkgs.adwaita-fonts
        pkgs.dejavu_fonts
        pkgs.fira-code
        pkgs.hack-font
        pkgs.ibm-plex
        pkgs.inconsolata
        pkgs.liberation_ttf
        pkgs.nerd-fonts.dejavu-sans-mono
        pkgs.nerd-fonts.caskaydia-mono
        pkgs.noto-fonts
        # The only emoji family here, and stylix.fonts.emoji names it. Without
        # it Stylix points at a family fontconfig cannot match and every emoji
        # falls back to a box.
        pkgs.noto-fonts-color-emoji
        pkgs.roboto
        pkgs.roboto-mono
        pkgs.source-code-pro
        pkgs.ttf_bitstream_vera
      ];
    };
}
