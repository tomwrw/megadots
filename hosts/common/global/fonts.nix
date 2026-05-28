{ pkgs, ... }:
{
  # Fonts installed on all hosts go here.
  fonts.packages = [
    pkgs.dejavu_fonts
    pkgs.fira-code
    pkgs.hack-font
    pkgs.ibm-plex
    pkgs.inconsolata
    pkgs.jetbrains-mono
    pkgs.liberation_ttf
    pkgs.nerd-fonts.dejavu-sans-mono
    pkgs.nerd-fonts.caskaydia-mono
    pkgs.noto-fonts
    pkgs.roboto
    pkgs.roboto-mono
    pkgs.source-code-pro
    pkgs.ttf_bitstream_vera
  ];
}
