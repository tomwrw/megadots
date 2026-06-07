# System-wide theming via Stylix, Home-Manager-only (no NixOS-level styling).
# Both hosts use the same scheme/wallpaper, so they're consolidated here rather
# than set per host.
{ inputs, self, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.stylix.homeManager =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = true;
        # Overlays conflict with home-manager.useGlobalPkgs; theming is applied
        # at the HM level instead.
        overlays.enable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
        # Root-anchored via the flake `self` (its outPath is the project root),
        # so this doesn't depend on how deep this aspect file sits.
        image = "${self}/assets/wallpaper/snake.png";
        polarity = "dark";
        targets = {
          firefox = {
            firefoxGnomeTheme.enable = true;
            profileNames = [ "default" ];
          };
          qt.enable = false;
        };
      };
    };
}
