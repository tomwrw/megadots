_:
let
  fontPkgs = pkgs: [
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
in
{
  den.aspects.desktop.fonts = {
    nixos =
      { pkgs, ... }:
      {
        fonts.packages = fontPkgs pkgs;
      };

    # Opt-in only (e.g. a standalone den.homes with no system font path).
    # Never included by 'roles.default' - a bare homeManager block on a
    # host-scope-only aspect is inert, so this is a named sub-aspect instead
    # of a silent no-op.
    provides.home.homeManager =
      { pkgs, ... }:
      {
        home.packages = fontPkgs pkgs;
        fonts.fontconfig.enable = true;
      };
  };
}
