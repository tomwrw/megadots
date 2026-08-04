{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.desktop.stylix.homeManager =
    { config, pkgs, ... }:
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = true;
        overlays.enable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
        image = ../../../assets/wallpaper/snake.png;
        polarity = "dark";
        targets = {
          firefox = {
            firefoxGnomeTheme.enable = true;
            profileNames = [ "default" ];
          };
          obsidian = {
            # Stylix wants the vault's absolute path so it can drop a CSS
            # snippet into it. Derived from homeDirectory rather than
            # hardcoded, so this aspect stays free of any username.
            vaultNames = [ "${config.home.homeDirectory}/Sync/Notes" ];
          };
          qt.enable = false;
        };
      };
    };
}
