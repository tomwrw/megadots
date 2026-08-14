_:
let
  fontPkgs = pkgs: [
    pkgs.dejavu_fonts
    pkgs.fira-code
    pkgs.hack-font
    pkgs.ibm-plex
    pkgs.inconsolata
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
  megadots.desktop.fonts = {
    description = "A system font set, with the same set offered as a provides.home sub-aspect for standalone homes.";

    nixos =
      { pkgs, ... }:
      {
        fonts.packages = fontPkgs pkgs;
      };

    # Opt-in only, for a standalone den.homes with no system font path.
    # roles.base never includes it. A bare homeManager block on a host-scope
    # aspect does nothing, so this is a named sub-aspect instead, included by
    # hand as megadots.desktop.fonts.provides.home.
    #
    # "home" is a safe name here precisely because it is a den schema entity
    # kind: den registers an automatic cross-policy for every provides.<name>
    # that is *not* a kind, delivering to an entity of that name. Kind names are
    # filtered out (nix/lib/aspects/fx/aspect/provide.nix), so this one never
    # fires on its own and only ever arrives where I include it. Renaming it to
    # something like "standalone" would quietly register a delivery policy.
    provides.home.homeManager =
      { pkgs, ... }:
      {
        home.packages = fontPkgs pkgs;
        fonts.fontconfig.enable = true;
      };
  };
}
